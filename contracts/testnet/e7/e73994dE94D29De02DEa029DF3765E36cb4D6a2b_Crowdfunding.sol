// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMetaPoint.sol";


contract Crowdfunding is AccessControlEnumerable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint16 public constant FUND_INTERVAL = 30;
    uint16 public constant RESTART_TIME_GAP = 2 * 3600; //两小时内重启开始时间不变
    uint256 public /*constant*/ MAX_FUND_AMOUNT = 500e18; //单用户最大投资金额
    address public lp = 0xdA0B47eD306F2bF6b128e5a84389b1f270932Cb6; //lp token
    address public metaPoint = 0x8347A810ff4d856A1571A5Ecc4672C0d0A52fA6c; //metaPoint address
    address public fee; //手续费地址
    address public donate; //捐赠池 功能?
    address public stake; //质押池 功能?
    address public mdao;
    uint256 public donateAmount;
    /*
    0:静态奖比例,1:经纪人奖比例,2:失败前三期返还本金比例,3:捐赠比例,4:质押池比例,5:失败当期彩蛋池奖励比例
    6:收益免费提现比例,7提现手续费比例 本金提现也收手续费,8:奖励锁定需点灯解锁比例,9:普通区单笔最大投资比例
    10: 快速区单笔最大投资比例
     */
    uint16[5] public equitys = [0, 0, 10, 20, 25];
    uint16[11] public rates = [100, 25, 800, 10, 50, 600, 200, 10, 200, 10, 50];
    uint16 public maxReserveRound = 5; //最多预约后续5期

    struct Account {
        uint256 priorityFundAmount; //优先额度
        uint256 freeWithdrawAmount; //免费提现额度
        uint256 lockedWithdrawAmount; //锁定提现额度
        uint256 unlockedAmount; //已解锁金额
        uint256 lastFundTime; //上次投资时间
        uint8 vips;
        uint40 point; //初始point数量
        address head; //原点上级
        bool pointFlag; // 是否记录point
    }

    struct Region {
        uint16 currentRound; //当前期数
        uint16 poolType; //区域类型(普通区/快速区)
        uint16 multiplier; //递增倍数千分位
        uint16 restartType; //重启类型 0:初始金额,1 底池50%
        uint256 initAmount; //初始金额
        uint256 period; //每期持续时间
        uint256 poolAmount; //底池金额
        uint256 startTime; //首期开始时间
    }
    //分区
    Region[] public regions;
    mapping(uint256 => Project[]) projects; //regionIndex => Project[]
    //众筹
    struct Project {
        uint16 state; //1:预约, 2:众筹中, 3:成功, 4:失败补偿, 5:盈利退款, 6:亏损退款
        uint16 version; //版本
        uint256 startTime; //开始时间
        uint256 targetAmount; //目标金额
        uint256 currentAmount; //当前金额
        uint256 reserveAmount; //预约金额
        uint256 reserveFundAmount; //预约支付金额
        uint256 refundAmount; //结束退款金额
        uint256 brokerRewardLeft; //经纪人奖剩余金额
    }

    struct ProjectFund {
        uint16 version; //版本
        uint256 fundAmount; //已支付支付金额
        uint256 reserveAmount; //预约金额
        uint256 reserveFundAmount; //预约支付金额
        uint256 refundAmount; //退回金额
        uint256 priorityRefundAmount; //退回优先额度
    }

    struct BrokerReward {
        uint16 version;
        uint256 amount;
    }

    //用户数据
    mapping(address => Account) public accounts;
    //address => regionIndex => round => funds
    mapping(address => mapping(uint256 => mapping(uint256 => ProjectFund))) projectFunds;
    mapping(address => mapping(uint256 => mapping(uint256 => BrokerReward))) brokerRewards;
    //address => regionIndex => projectIds
    mapping(address => mapping(uint256 => uint256[])) projectIds; //参与的众筹id列表
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) harvestableIds; //未提取收益id列表
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) brokerRewardIds; //经纪人收益期数

    error ProjectStateError();
    error ProjectRoundError();
    error ProjectTimeError();
    error ProjectAmountError();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OPERATOR_ROLE, _msgSender());
        //TODO test
        fee = 0x221A126E0F2B4A6c5848689145589f9A229dc3aa;
        donate = 0x810C2dd185dFd08b8d5656175f4f335a0ea61C78;
        stake = 0x2507012E0728Fb774325FEaD19fD106944dBa0E9;
        mdao = 0x221A126E0F2B4A6c5848689145589f9A229dc3aa;
    }

    function setEquitys(uint256 _index, uint16 _equity) external onlyRole(OPERATOR_ROLE) {
        equitys[_index] = _equity;
    }

    function upgrade(address _addr, uint8 _vips) external onlyRole(OPERATOR_ROLE) {
        accounts[_addr].vips = _vips;
    }

    //设置地址参数
    function setAddresses(address _fee, address _donate, address _stake) external onlyRole(OPERATOR_ROLE) {
        fee = _fee;
        donate = _donate;
        stake = _stake;
    }

    //设置奖励比例
    function setRate(uint16 index, uint16 rate) external onlyRole(OPERATOR_ROLE) {
        rates[index] = rate;
    }

    function setMaxReserveRound(uint16 _maxRound) external onlyRole(OPERATOR_ROLE) {
        maxReserveRound = _maxRound;
    }

    //设置分区参数
    function setRegionParams(uint256 _regionIndex, uint256 _period, uint16 _multiplier, uint16 _restartType) external onlyRole(OPERATOR_ROLE) {
        regions[_regionIndex].period = _period;
        regions[_regionIndex].multiplier = _multiplier;
        regions[_regionIndex].restartType = _restartType;
    }

    //添加分区
    function addRegion(uint256 period, uint16 poolType, uint256 initAmount, uint16 multiplier, uint256 startTime, uint16 restartType) external /*onlyRole(OPERATOR_ROLE)*/ {
        require(initAmount > 0, "wrong initAmount");
        require(multiplier > 1000, "wrong multiplier");
        regions.push(
            Region({
        period : period,
        poolType : poolType,
        initAmount : initAmount,
        multiplier : multiplier,
        startTime : startTime,
        restartType : restartType,
        currentRound : 0,
        poolAmount : 0
        })
        );
        _addProject(regions.length - 1);
    }

    function addProject(uint256 regionIndex) external /*onlyRole(OPERATOR_ROLE)*/ {
        Region memory region = regions[regionIndex];
        require(region.initAmount > 0, "region not exists");
        uint32 diff = region.poolType == 1 ? 1 : 5;
        require(projects[regionIndex].length - region.currentRound < diff);
        _addProject(regionIndex);
    }

    function _addProject(uint256 _regionIndex) internal {
        Project storage p = projects[_regionIndex].push();
        uint256 pl = projects[_regionIndex].length;
        Region memory region = regions[_regionIndex];
        //快速区状态为开始2,普通区为预约中1
        p.state = region.poolType == 1 ? 2 : 1;
        if (pl == 1) {
            p.targetAmount = region.initAmount;
            p.startTime = region.startTime;
        } else {
            //重置起始额度
            if (projects[_regionIndex][pl - 2].state == 4) {
                p.targetAmount = (regions[_regionIndex].restartType == 1 && regions[_regionIndex].poolAmount > 1e18)
                ? roundup(regions[_regionIndex].poolAmount / 2, 1e18) : regions[_regionIndex].initAmount;
            } else {
                p.targetAmount = roundup((projects[_regionIndex][pl - 2].targetAmount * region.multiplier) / 1000, 1e18);
            }
            p.startTime = region.poolType == 1 ? block.timestamp : projects[_regionIndex][pl - 2].startTime + region.period;
        }
    }

    //参与众筹
    function fund(uint256 _regionIndex, uint256 _amount) external {
        require(recordMetaPoint(msg.sender), "no meta point account");
        require(_amount > 0, "zero amount error");
        require(accounts[msg.sender].lastFundTime + FUND_INTERVAL < block.timestamp, "funding time limited");
        uint16 _poolType = regions[_regionIndex].poolType;
        uint16 _round = regions[_regionIndex].currentRound;
        Project storage p = projects[_regionIndex][_round];
        //前一期超时超时重置
        if (block.timestamp > p.startTime + regions[_regionIndex].period) {
            finishProject(_regionIndex);
            _round++;
            p = projects[_regionIndex][_round];
        }
        uint256 _maxAmount = getMaxAmountPerTime(p.targetAmount, _poolType);
        require(_amount <= _maxAmount, "max amount limited");
        if (block.timestamp < p.startTime || block.timestamp > p.startTime + regions[_regionIndex].period) revert ProjectTimeError();
        if (p.state > 2) revert ProjectStateError();
        if (p.state < 2) p.state = 2;
        uint256 amountLeft = p.targetAmount - p.currentAmount - p.reserveFundAmount;
        if (amountLeft == 0) revert ProjectAmountError();
        uint16 version = p.version;
        ProjectFund storage pf = projectFunds[msg.sender][_regionIndex][_round];
        processRefund(pf, version);
        pf.version = version;
        uint256 fundAmount = min(_amount, amountLeft);
        IERC20(lp).safeTransferFrom(msg.sender, address(this), fundAmount);
        processBrokerReward(msg.sender, _regionIndex, _round, version, fundAmount);
        if (_amount > amountLeft) {
            accounts[msg.sender].priorityFundAmount += _amount;
        }
        addProjectId(msg.sender, _regionIndex, _round);
        p.currentAmount += fundAmount;
        pf.fundAmount += fundAmount;
        regions[_regionIndex].poolAmount += fundAmount;
        accounts[msg.sender].lastFundTime = block.timestamp;
        //自动结束本期
        if (_amount >= amountLeft) finishProject(_regionIndex);
    }

    //预约
    function reserve(uint256 _regionIndex, uint256 _round, uint256 _amount) external {
        require(recordMetaPoint(msg.sender), "no meta point account");
        require(_amount > 0, "zero amount error");
        require(regions[_regionIndex].poolType == 0, "wrong region");
        uint16 currentRound = regions[_regionIndex].currentRound;
        uint256 _maxRound = min(projects[_regionIndex].length, currentRound + maxReserveRound);
        if (_round <= currentRound || _round >= _maxRound) revert ProjectStateError();
        Project storage p = projects[_regionIndex][_round];
        if (block.timestamp > p.startTime) revert ProjectTimeError();
        require(_amount * 2 <= p.targetAmount - p.reserveFundAmount, "no reserve amount left");
        require(_amount <= accounts[msg.sender].priorityFundAmount, "priority amount not enough");
        uint16 version = p.version;
        ProjectFund storage pf = projectFunds[msg.sender][_regionIndex][_round];
        processRefund(pf, version);
        pf.reserveAmount += _amount;
        pf.version = version;
        p.reserveAmount += _amount;
        accounts[msg.sender].priorityFundAmount -= _amount;
        //加入预约列表
        addProjectId(msg.sender, _regionIndex, _round);
    }

    function addProjectId(address _account, uint256 _regionIndex, uint256 _round) internal {
        if (!harvestableIds[_account][_regionIndex].contains(_round)) {
            harvestableIds[_account][_regionIndex].add(_round);
            projectIds[_account][_regionIndex].push(_round);
        }
    }

    function processRefund(ProjectFund storage pf, uint16 version) internal {
        if (pf.version < version) {
            uint256 _fundAmount = pf.fundAmount;
            uint256 _reserveAmount = pf.reserveAmount;
            //之前的版本有预约支付,需退回
            if (_fundAmount > 0) {
                pf.priorityRefundAmount += _reserveAmount;
                pf.reserveAmount = 0;
                pf.refundAmount += _fundAmount;
                pf.fundAmount = 0;
                pf.reserveFundAmount = 0;
            } else if (_reserveAmount > 0) {
                pf.priorityRefundAmount += _reserveAmount;
                pf.reserveAmount = 0;
            }
        }
    }

    //完成预约
    function finishReserve(uint256 _regionIndex, uint256 _round) external {
        Project storage p = projects[_regionIndex][_round];
        require(block.timestamp < p.startTime, "payment time passed");
        uint16 version = p.version;
        ProjectFund storage pf = projectFunds[msg.sender][_regionIndex][_round];
        uint256 reserveAmount = pf.reserveAmount;
        uint256 fundAmount = pf.fundAmount;
        require(pf.version == version && reserveAmount > 0, "not reserved");
        require(reserveAmount > fundAmount, "already paid");
        uint256 _amount = reserveAmount - fundAmount;
        IERC20(lp).transferFrom(msg.sender, address(this), _amount);
        pf.reserveFundAmount += _amount;
        pf.fundAmount += _amount;
        //预约支付暂不计入底池额度, 当期结束时底池增加
        p.reserveFundAmount += _amount;
        accounts[msg.sender].lastFundTime = block.timestamp;
        processBrokerReward(msg.sender, _regionIndex, _round, version, _amount);
        if (!harvestableIds[msg.sender][_regionIndex].contains(_round)) {
            harvestableIds[msg.sender][_regionIndex].add(_round);
            projectIds[msg.sender][_regionIndex].push(_round);
        }
    }

    //查询预约额度
    function pendingForFinish(address _account, uint256 _regionIndex, uint256 _round) public view returns (uint256 reserveAmount, uint256 reserveFundAmount) {
        ProjectFund storage pf = projectFunds[_account][_regionIndex][_round];
        if (pf.version == projects[_regionIndex][_round].version) {
            reserveAmount = pf.reserveAmount;
            reserveFundAmount = pf.reserveFundAmount;
        }
    }
    //完当前期(成功或失败), 并根据状态更新前三期的状态(盈利退款/亏损退款)
    function finishProject(uint256 _regionIndex) public {
        uint16 _round = regions[_regionIndex].currentRound;
        Project storage p = projects[_regionIndex][_round];
        require(block.timestamp > p.startTime + regions[_regionIndex].period || p.targetAmount == p.currentAmount, "not met finish condition");
        if (p.state > 2) revert ProjectStateError();
        //TODO 将预约支付金额放回池中
        uint256 _poolAmount = regions[_regionIndex].poolAmount + p.reserveFundAmount;
        uint256 _currentAmount = p.currentAmount;
        if (_currentAmount == p.targetAmount) {
            //当期成功
            p.state = 3;
            //前第三期盈利退款
            if (_round >= 3 && projects[_regionIndex][_round - 3].state == 3) {
                Project storage p3 = projects[_regionIndex][_round - 3];
                p3.state = 5;
                //质押池和捐赠金额
                uint256 _targetAmount = p3.targetAmount;
                uint256 _stakeAmount = (_targetAmount * rates[4]) / 1000;
                uint256 _donateAmount = (_targetAmount * rates[3]) / 1000;
                //剩余的经纪人奖放回池中
                uint256 _refundAmount = (_targetAmount * (1000 + rates[0] + rates[1])) / 1000 - p3.brokerRewardLeft;
                if (_stakeAmount > 0) processStake(_stakeAmount);
                if (_donateAmount > 0) donateAmount += _donateAmount;
                p3.refundAmount = _refundAmount;
                _poolAmount -= (_refundAmount + _stakeAmount + _donateAmount);
            }
        } else {
            //当期失败
            p.state = 4;
            //更新奖池
            if (_round > 0) {
                //前三期亏损退款
                uint256 start = _round >= 3 ? _round - 3 : 0;
                for (uint256 i = start; i < _round; i++) {
                    Project storage pi = projects[_regionIndex][i];
                    if (pi.state == 3) {
                        pi.state = 6;
                        pi.refundAmount = (pi.targetAmount * (rates[2])) / 1000;
                        _poolAmount -= pi.refundAmount;
                    }
                }
            }
            //当期奖励底池50%
            if (_currentAmount > 0) {
                _poolAmount -= _currentAmount;
                uint256 _bonusAmount = (_poolAmount * rates[5]) / 1000;
                _poolAmount -= _bonusAmount;
                p.refundAmount = _bonusAmount + _currentAmount;
            }
            resetProjects(_regionIndex, _round);
        }
        regions[_regionIndex].poolAmount = _poolAmount;
        //新增一期
        _addProject(_regionIndex);
        //更新正在进行的期数
        regions[_regionIndex].currentRound++;
    }

    //重置后面期数参数
    function resetProjects(uint256 _regionIndex, uint256 _round) internal {
        uint256 _length = projects[_regionIndex].length;
        uint16 _multiplier = regions[_regionIndex].multiplier;
        uint256 _period = regions[_regionIndex].period;
        bool resetTime = block.timestamp > projects[_regionIndex][_round].startTime + RESTART_TIME_GAP;
        uint256 _targetAmount;
        uint256 _startTime;
        for (uint256 i = _round + 1; i < _length; i++) {
            Project storage p = projects[_regionIndex][i];
            if (i == _round + 1) {
                _targetAmount = (regions[_regionIndex].restartType == 1 && regions[_regionIndex].poolAmount > 0)
                ? roundup(regions[_regionIndex].poolAmount / 2, 1e18) : regions[_regionIndex].initAmount;
                p.targetAmount = _targetAmount;
                if (resetTime) {
                    _startTime = p.startTime;
                    _startTime = block.timestamp > _startTime + _period ? block.timestamp : _startTime;
                    p.startTime = _startTime;
                }
            } else {
                p.targetAmount = roundup((_targetAmount * _multiplier) / 1000, 1e18);
                if (resetTime) p.startTime = _startTime + _period;
            }
            if (p.reserveAmount > 0) {
                ++p.version;
                p.reserveAmount = 0;
                p.reserveFundAmount = 0;
                p.brokerRewardLeft = 0;
            }
        }
    }

    //查询收益
    function pending(
        address _account,
        uint256 _regionIndex,
        uint256 _round
    )
    public
    view
    returns (
        uint256[] memory amounts, //0:投入本金,1:返回本金,2:静态收益,3:免费提现额度,4:优先额度
        uint16 state,
        uint16 version,
        bool restart
    )
    {amounts = new uint256[](5);
        Project storage p = projects[_regionIndex][_round];
        ProjectFund storage pf = projectFunds[_account][_regionIndex][_round];
        uint256 _fundAmount = pf.fundAmount;
        amounts[0] = _fundAmount;
        state = p.state;
        version = p.version;
        if (pf.version == projects[_regionIndex][_round].version) {
            //4:失败补偿, 5:盈利退款, 6:亏损退款
            if (state == 4) {
                amounts[1] = _fundAmount;
                uint256 _currentAmount = p.currentAmount;
                amounts[2] = _currentAmount == 0 ? 0 : ((p.refundAmount - _currentAmount) * _fundAmount) / _currentAmount;
            } else if (state == 5) {
                amounts[1] = _fundAmount;
                amounts[2] = (_fundAmount * rates[0]) / 1000;
            } else if (state == 6) {
                amounts[1] = (_fundAmount * rates[2]) / 1000;
                amounts[3] = (_fundAmount * rates[6]) / rates[7];
                //等值免费提现额度
                amounts[4] = _fundAmount;
            }
            //预约退款
            amounts[1] += pf.refundAmount;
            amounts[4] += pf.priorityRefundAmount;
            amounts[3] += pf.refundAmount;
        } else {
            restart = true;
            amounts[4] += (pf.reserveAmount + pf.priorityRefundAmount);
            amounts[1] += (pf.reserveFundAmount + pf.refundAmount);
            amounts[3] += (pf.reserveFundAmount + pf.refundAmount);
        }

    }

    function _harvest(
        uint256 _refundAmount,
        uint256 _rewardAmount,
        uint256 _freeWithdrawAmount,
        uint256 _priorityFundAmount
    ) internal {
        uint256 lockedAmount = (_rewardAmount * rates[8]) / 1000;
        if (lockedAmount > 0) {
            accounts[msg.sender].lockedWithdrawAmount += lockedAmount;
        }
        if (_priorityFundAmount > 0) {
            accounts[msg.sender].priorityFundAmount += _priorityFundAmount;
        }
        uint256 freeWithdrawAmount = accounts[msg.sender].freeWithdrawAmount;
        if (_freeWithdrawAmount > 0) {
            freeWithdrawAmount += _freeWithdrawAmount;
        }
        uint256 _amount = _refundAmount + (_rewardAmount - lockedAmount);
        if (_amount > 0) {
            //使用免费提现额度
            if (freeWithdrawAmount >= _amount) {
                freeWithdrawAmount -= _amount;
                IERC20(lp).safeTransfer(msg.sender, _amount);
            } else {
                uint256 _feeAmount = ((_amount - freeWithdrawAmount) * rates[7]) / 1000;
                freeWithdrawAmount = 0;
                IERC20(lp).safeTransfer(msg.sender, _amount - _feeAmount);
                IERC20(lp).safeTransfer(fee, _feeAmount);
            }

        }
        accounts[msg.sender].freeWithdrawAmount = freeWithdrawAmount;
    }

    function recordMetaPoint(address _account) public returns (bool) {
        if (!accounts[_account].pointFlag) {
            IMetaPoint.Account memory account = IMetaPoint(metaPoint).accounts(_account);
            address head = account.head;
            if (head == address(0)) return false;
            if (account.vip < 2) {
                accounts[_account].vips = account.vip;
            } else if (accounts[_account].vips == 0) {
                accounts[_account].vips = 1;
            }
            accounts[_account].point = account.point;
            accounts[_account].head = account.head;
            accounts[_account].pointFlag = true;
        }
        return true;
    }

    //经纪人奖
    function processBrokerReward(address _addr, uint256 _regionIndex, uint256 _round, uint16 _version, uint256 _fundAmount) private {
        uint16 used = 0;
        uint16 level = 0;
        for (uint256 i = 0; i < 45; i++) {
            address parent = accounts[_addr].head;
            if (parent == address(0)) {
                parent = IMetaPoint(metaPoint).accounts(_addr).head;
            }
            if (parent == address(0)) {
                break;
            }
            uint8 parentLevel = accounts[parent].vips;
            if (equitys[parentLevel] > equitys[level]) {
                uint16 diff = equitys[parentLevel] - equitys[level];
                uint256 _amount = (_fundAmount * diff) / 1000;
                used += diff;
                BrokerReward storage br = brokerRewards[parent][_regionIndex][_round];
                brokerRewardIds[parent][_regionIndex].add(_round);
                if (br.version == _version) {
                    br.amount += _amount;
                } else {
                    br.version = _version;
                    br.amount = _amount;
                }
                level = parentLevel;
            }
            _addr = parent;
        }
        if (rates[1] > used) {
            projects[_regionIndex][_round].brokerRewardLeft += _fundAmount * (rates[1] - used) / 1000;
        }
    }

    //处理捐赠
    function processDonate() public {
        require(donateAmount > 0, "no donate amount");
        address[] memory donates = IDonate(donate).queryDonatedList();
        require(donates.length > 0, "Donate is empty");
        uint256 perDonate = donateAmount / donates.length;
        donateAmount = 0;
        for (uint256 i = 0; i < donates.length; i++) {
            IERC20(lp).safeTransfer(donates[i], perDonate);
        }
    }

    function processStake(uint256 amount) internal {
        uint256 stakeAmount = (amount * 4) / 5;
        IERC20(lp).safeApprove(stake, stakeAmount);
        IMebLpStake(stake).award(lp, stakeAmount);
        IERC20(lp).safeTransfer(mdao, amount - stakeAmount);
    }

    //领取所有收益
    function harvestAll(uint256 _regionIndex, uint256[] calldata _roundIds) external {
        (uint256 refundAmount, uint256 rewardAmount, uint256 freeWithdrawAmount, uint256 priorityFundAmount) = (0, 0, 0, 0);
        for (uint256 i = 0; i < _roundIds.length; i++) {
            if (harvestableIds[msg.sender][_regionIndex].contains(_roundIds[i])) {
                (uint256[] memory _amounts, uint16 state, uint16 version, bool restart) = pending(msg.sender, _regionIndex, _roundIds[i]);
                refundAmount += _amounts[1];
                rewardAmount += _amounts[2];
                freeWithdrawAmount += _amounts[3];
                priorityFundAmount += _amounts[4];
                if (state > 3) {
                    //已结束
                    harvestableIds[msg.sender][_regionIndex].remove(_roundIds[i]);
                } else {
                    ProjectFund storage pf = projectFunds[msg.sender][_regionIndex][_roundIds[i]];
                    pf.refundAmount = 0;
                    pf.priorityRefundAmount = 0;
                    //有重启
                    if (restart == true) {
                        pf.version = version;
                        pf.reserveAmount = 0;
                        pf.reserveFundAmount = 0;
                    }
                }
            }
        }
        if (refundAmount > 0 || priorityFundAmount > 0) _harvest(refundAmount, rewardAmount, freeWithdrawAmount, priorityFundAmount);
    }

    //查询可解锁额度
    function pendingForUnlock(address _account) public view returns (uint256 lockedAmount, uint256 unlockAmount) {
        uint256 unlockedAmount = accounts[_account].unlockedAmount;
        lockedAmount = accounts[_account].lockedWithdrawAmount - unlockedAmount;
        if (accounts[_account].pointFlag) {
            uint256 point = IMetaPoint(metaPoint).accounts(_account).point;
            uint256 _point = accounts[_account].point;
            if (point > _point) {
                uint256 _unlockAmount = (point - _point) * 50e18;
                unlockAmount = _unlockAmount > unlockedAmount ? _unlockAmount - unlockedAmount : 0;
            }
        }
    }

    //通过point解锁
    function unlockWithdraw() external {
        (uint256 lockedAmount, uint256 unlockAmount) = pendingForUnlock(msg.sender);
        require(lockedAmount > 0, "no amount for unlock");
        require(unlockAmount > 0, "no point for unlock");
        uint256 _amount = min(lockedAmount, unlockAmount);
        accounts[msg.sender].unlockedAmount += _amount;
        IERC20(lp).safeTransfer(msg.sender, _amount);
    }

    function pendingForBrokerReward(address _account, uint256 _regionIndex, uint256[] calldata _roundIds) public view returns (uint256 amount, uint16[] memory states){
        states = new uint16[](_roundIds.length);
        for (uint256 i = 0; i < _roundIds.length; i++) {
            uint256 _round = _roundIds[i];
            uint16 version = projects[_regionIndex][_round].version;
            uint16 state = projects[_regionIndex][_round].state;
            states[i] = state;
            if (state == 5 && brokerRewards[_account][_regionIndex][_round].version == version
                && brokerRewardIds[_account][_regionIndex].contains(_round)) {
                amount += brokerRewards[_account][_regionIndex][_round].amount;
            }
        }
    }

    function withdrawBrokerReward(uint256 _regionIndex, uint256[] calldata _roundIds) external {
        (uint256 amount, uint16[] memory states) = pendingForBrokerReward(msg.sender, _regionIndex, _roundIds);
        for (uint256 i = 0; i < _roundIds.length; i++) {
            if (states[i] > 3) brokerRewardIds[msg.sender][_regionIndex].remove(_roundIds[i]);
        }
        if (amount > 0) _harvest(0, amount, 0, 0);
    }

    function getRegionCount() public view returns (uint256) {
        return regions.length;
    }

    function getProjectCount(uint256 _regionIndex) public view returns (uint256) {
        return projects[_regionIndex].length;
    }

    function getProjects(
        uint256 _regionIndex,
        uint256 _offset,
        uint256 _size
    ) external view returns (Project[] memory projectList) {
        uint256 length = projects[_regionIndex].length;
        require(_offset + _size <= length, "out of bound");
        projectList = new Project[](_size);
        for (uint256 i = 0; i < _size; i++) {
            projectList[i] = projects[_regionIndex][_offset + i];
        }
    }
    //获取众筹期数id _type 1:众筹期数历史,2:待提取期数列表,3:预约期数列表,4 经纪人收益期数列表
    function getProjectIds(address _account, uint256 _regionIndex) public view returns (uint256[] memory pids) {
        pids = projectIds[_account][_regionIndex];
    }

    function getHarvestableIds(address _account, uint256 _regionIndex) public view returns (uint256[] memory pids) {
        pids = harvestableIds[_account][_regionIndex].values();
    }

    //单次最大投资金额
    function getMaxAmountPerTime(uint256 _targetAmount, uint16 _poolType) public view returns (uint256 maxAmountPerTime) {
        uint16 _rate = _poolType == 0 ? rates[9] : rates[10];
        uint256 _max = (_targetAmount * _rate) / 1000;
        maxAmountPerTime = _max > MAX_FUND_AMOUNT ? _max : MAX_FUND_AMOUNT;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function roundup(uint256 a, uint256 m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }

    function parent_mapping(address[] calldata addrs, address[] calldata parents) external onlyRole(OPERATOR_ROLE) {
        require(addrs.length == parents.length, "data error.");
        for (uint16 i = 0; i < addrs.length; i++) {
            accounts[addrs[i]].head = parents[i];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IMetaPoint {
    struct Account {
        uint256 srd;
        uint256 srw;
        address head;
        uint8 vip;
        uint40 point;
        uint40 effect;
        uint256 wdm;
        uint256 wd;
        uint256 wda;
        uint256 grd;
        uint40 rootSn;
    }

    function accounts(address addr) external view returns (Account memory);
}

interface IDonate {
    function queryDonatedList() external view returns (address[] memory);
}

interface IMebLpStake {
    function award(address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}