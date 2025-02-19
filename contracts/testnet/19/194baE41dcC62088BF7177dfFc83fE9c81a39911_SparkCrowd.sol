// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./ICrowdAccount.sol";

contract SparkCrowd is AccessControlEnumerable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    uint16 public constant RESTART_TIME_GAP = 2 * 3600;
    address public constant LP = 0xdA0B47eD306F2bF6b128e5a84389b1f270932Cb6;
    address public fee = 0x221A126E0F2B4A6c5848689145589f9A229dc3aa;
    address public donate = 0x221A126E0F2B4A6c5848689145589f9A229dc3aa;
    address public crowdAccount = 0x9fBfFb00fa146e43c9a1c4303F882531239AFc2a;
    uint256 public donateAmount;
    uint16[] public bonus = [0, 0, 10, 20, 30, 40];
    /*
    0:静态奖比例,1:手续费充值比例,2:失败前三期返还本金比例,3:捐赠比例,4:质押池比例,5:失败当期彩蛋池奖励比例
    6:最大预约比例,7提现手续费比例 本金提现也收手续费,8:奖励锁定需点灯解锁比例,9:普通区单笔最大投资比例
    10:单次最大参与额度(单位1e18), 11:前第几期开始返回本金, 12:最大预约期数,13:抢购时间(分钟)
     */
    uint16[] public defaultParams = [150, 20, 750, 30, 0, 600, 500, 10, 0, 10, 100, 3, 5, 10];
    uint16 public fundInterval = 6;

    struct Region {
        uint32 currentRound;
        uint16 multiplier;
        uint256 initAmount;
        uint256 period;
        uint256 poolAmount;
        uint256 startTime;
        uint16[] params;
    }

    Region[] public regions;
    mapping(uint256 => Project[]) projects;

    struct Project {
        uint16 state;
        uint16 version;
        uint256 startTime;
        uint256 targetAmount;
        uint256 currentAmount;
        uint256 reserveAmount;
        uint256 refundAmount;
        uint256 brokerReward;
    }

    struct ProjectFund {
        uint16 version;
        uint256 fund;
        uint256 refund;
        uint256 reserve;
        uint256 reserveFund;
        uint256 reserveRefund;
        uint256 priorityRefund;
    }

    struct BrokerReward {
        uint16 version;
        uint256 amount;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => ProjectFund))) projectFunds;
    mapping(address => mapping(uint256 => mapping(uint256 => BrokerReward))) brokerRewards;
    mapping(address => mapping(uint256 => uint256[])) projectIds;
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) harvestableIds;
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) brokerRewardIds;
    mapping(address => uint256) lastFundTime;
    mapping(address => bool) public leverageMap;
    mapping(address => bool) daoMap;

    error ProjectStateError();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setLeverageFlag(bool flag) external {
        require(ICrowdAccount(crowdAccount).accountVips(msg.sender) >= 3, "account level limited");
        for (uint256 i = 0; i < regions.length; i++) {
            if (harvestableIds[msg.sender][i].length() > 0) revert("fund limited");
        }
        leverageMap[msg.sender] = flag;
    }

    function setDaoFlag(address addr, bool flag) external onlyRole(OPERATOR_ROLE) {
        daoMap[addr] = flag;
    }

    function setBonus(uint256 _index, uint16 _bonus) external onlyRole(OPERATOR_ROLE) {
        bonus[_index] = _bonus;
    }

    function setAddresses(
        address _fee,
        address _donate,
        address _crowdAccount
    ) external onlyRole(OPERATOR_ROLE) {
        fee = _fee;
        donate = _donate;
        crowdAccount = _crowdAccount;
    }

    function setRegionParams(
        uint256 regionIndex,
        uint16 paramIndex,
        uint16 value
    ) external onlyRole(OPERATOR_ROLE) {
        regions[regionIndex].params[paramIndex] = value;
    }

    function getRegionParams(uint256 regionIndex) external view returns (uint16[] memory) {
        return regions[regionIndex].params;
    }

    function setFundInterval(uint16 interval) external onlyRole(OPERATOR_ROLE) {
        fundInterval = interval;
    }

    function setRegionInitParams(
        uint256 regionIndex,
        uint256 period,
        uint256 initAmount,
        uint16 multiplier
    ) external onlyRole(OPERATOR_ROLE) {
        regions[regionIndex].period = period;
        regions[regionIndex].initAmount = initAmount;
        regions[regionIndex].multiplier = multiplier;
    }

    function addRegion(
        uint256 period,
        uint256 initAmount,
        uint16 multiplier,
        uint256 startTime
    ) external onlyRole(OPERATOR_ROLE) {
        regions.push(
            Region({
                period: period,
                initAmount: initAmount,
                multiplier: multiplier,
                startTime: startTime,
                currentRound: 0,
                poolAmount: 0,
                params: defaultParams
            })
        );
        _addProject(regions.length - 1);
    }

    function addProject(uint256 regionIndex) external onlyRole(OPERATOR_ROLE) {
        require(regions[regionIndex].initAmount > 0, "region not exists");
        require(projects[regionIndex].length - regions[regionIndex].currentRound < regions[regionIndex].params[12]);
        _addProject(regionIndex);
    }

    function _addProject(uint256 regionIndex) internal {
        Project storage p = projects[regionIndex].push();
        uint256 pl = projects[regionIndex].length;
        p.state = 1;
        if (pl == 1) {
            p.targetAmount = regions[regionIndex].initAmount;
            p.startTime = regions[regionIndex].startTime;
        } else {
            if (projects[regionIndex][pl - 2].state == 4) {
                p.targetAmount = regions[regionIndex].initAmount;
            } else {
                p.targetAmount = roundup((projects[regionIndex][pl - 2].targetAmount * regions[regionIndex].multiplier) / 1000, 1e18);
            }
            p.startTime = projects[regionIndex][pl - 2].startTime + regions[regionIndex].period;
        }
    }

    function fund(uint256 regionIndex, uint256 amount) external {
        require(ICrowdAccount(crowdAccount).accountVips(msg.sender) > 0, "account limited");
        require(amount > 0, "zero amount error");
        require(lastFundTime[msg.sender] + fundInterval < block.timestamp || daoMap[msg.sender] == true, "funding time limited");
        uint32 round = regions[regionIndex].currentRound;
        Project storage p = projects[regionIndex][round];
        if (block.timestamp > p.startTime + regions[regionIndex].period) {
            finishProject(regionIndex);
            round++;
            p = projects[regionIndex][round];
        }
        require(amount <= getMaxAmountPerTime(regionIndex, p.targetAmount), "max amount limited");
        require(
            block.timestamp > p.startTime && block.timestamp < p.startTime + min(regions[regionIndex].period, uint256(regions[regionIndex].params[13]) * 60),
            "funding time limited"
        );
        if (p.state > 2) revert ProjectStateError();
        if (p.state < 2) p.state = 2;
        uint256 amountLeft = p.targetAmount - p.currentAmount;
        require(amountLeft > 0, "no fund amount left");
        uint16 version = p.version;
        ProjectFund storage pf = projectFunds[msg.sender][regionIndex][round];
        processRefund(pf, version);
        pf.version = version;
        uint256 fundAmount = min(amount, amountLeft);
        processFund(pf, regionIndex, fundAmount);
        processBrokerReward(msg.sender, regionIndex, round, version, fundAmount);
        addProjectId(msg.sender, regionIndex, round);
        p.currentAmount += fundAmount;
        lastFundTime[msg.sender] = block.timestamp;
        if (amount >= amountLeft) finishProject(regionIndex);
    }

    function reserve(
        uint256 regionIndex,
        uint256 round,
        uint256 amount
    ) external {
        require(ICrowdAccount(crowdAccount).accountVips(msg.sender) > 0, "account limited");
        require(amount > 0, "zero amount error");
        require(lastFundTime[msg.sender] + fundInterval < block.timestamp || daoMap[msg.sender] == true, "reserve time limited");
        Project storage p = projects[regionIndex][round];
        uint256 targetAmount = p.targetAmount;
        require(amount <= getMaxAmountPerTime(regionIndex, targetAmount), "max amount limited");
        require((amount + p.reserveAmount) <= (targetAmount * regions[regionIndex].params[6]) / 1000, "no reserve amount left");
        uint256 priorityFundAmount = ICrowdAccount(crowdAccount).priorityFundAmount(msg.sender);
        require(amount <= priorityFundAmount, "priority amount not enough");
        uint32 currentRound = regions[regionIndex].currentRound;
        uint256 maxRound = min(projects[regionIndex].length, currentRound + regions[regionIndex].params[12]);
        if (p.state > 1 || round >= maxRound) revert ProjectStateError();
        require(block.timestamp < p.startTime, "funding time limited");
        uint16 version = p.version;
        ProjectFund storage pf = projectFunds[msg.sender][regionIndex][round];
        processRefund(pf, version);
        pf.version = version;
        pf.reserve += amount;
        p.reserveAmount += amount;
        ICrowdAccount(crowdAccount).setPriorityFundAmount(msg.sender, priorityFundAmount - amount);
        lastFundTime[msg.sender] = block.timestamp;
        addProjectId(msg.sender, regionIndex, round);
    }

    function addProjectId(
        address account,
        uint256 regionIndex,
        uint256 round
    ) internal {
        if (harvestableIds[account][regionIndex].add(round)) {
            projectIds[account][regionIndex].push(round);
        }
    }

    function processRefund(ProjectFund storage pf, uint16 version) internal {
        if (pf.version < version) {
            uint256 fundAmount = pf.fund;
            uint256 reserveAmount = pf.reserve;
            if (reserveAmount > 0) {
                pf.priorityRefund += reserveAmount;
                pf.reserve = 0;
            }
            if (fundAmount > 0) {
                pf.reserveRefund += fundAmount;
                pf.fund = 0;
                pf.reserveFund = 0;
                pf.refund = 0;
            }
        }
    }

    function processFund(
        ProjectFund storage pf,
        uint256 regionIndex,
        uint256 amount
    ) internal {
        uint256 leverageAmount = getLeverageAmount(msg.sender, regionIndex, amount);
        if (leverageAmount < amount) {
            IERC20(LP).safeTransferFrom(msg.sender, address(this), leverageAmount);
            pf.refund += (amount - leverageAmount);
        } else {
            IERC20(LP).safeTransferFrom(msg.sender, address(this), amount);
        }
        pf.fund += amount;
    }

    function finishReserve(uint256 regionIndex, uint256 round) external {
        Project storage p = projects[regionIndex][round];
        require(block.timestamp < p.startTime, "payment time passed");
        uint16 version = p.version;
        ProjectFund storage pf = projectFunds[msg.sender][regionIndex][round];
        uint256 reserveAmount = pf.reserve;
        uint256 fundAmount = pf.fund;
        require(pf.version == version && reserveAmount > 0, "not reserved");
        require(reserveAmount > fundAmount, "already paid");
        uint256 amount = reserveAmount - fundAmount;
        processFund(pf, regionIndex, amount);
        pf.reserveFund += amount;
        p.currentAmount += amount;
        processBrokerReward(msg.sender, regionIndex, round, version, amount);
        if (!harvestableIds[msg.sender][regionIndex].contains(round)) {
            harvestableIds[msg.sender][regionIndex].add(round);
            projectIds[msg.sender][regionIndex].push(round);
        }
    }

    function pendingForFinish(
        address account,
        uint256 regionIndex,
        uint256 round
    ) external view returns (uint256 reserveAmount, uint256 reserveFundAmount) {
        ProjectFund storage pf = projectFunds[account][regionIndex][round];
        if (pf.version == projects[regionIndex][round].version) {
            reserveAmount = pf.reserve;
            reserveFundAmount = pf.reserveFund;
        }
    }

    function finishProject(uint256 regionIndex) public {
        uint32 round = regions[regionIndex].currentRound;
        Project storage p = projects[regionIndex][round];
        require(block.timestamp > p.startTime + regions[regionIndex].period || p.targetAmount == p.currentAmount, "finish condition limited");
        if (p.state > 2) revert ProjectStateError();
        uint256 currentAmount = p.currentAmount;
        uint256 poolAmount = regions[regionIndex].poolAmount + currentAmount;
        if (currentAmount == p.targetAmount) {
            p.state = 3;
            {
                uint16 backRound = regions[regionIndex].params[11];
                if (round >= backRound && projects[regionIndex][round - backRound].state == 3) {
                    Project storage p2 = projects[regionIndex][round - backRound];
                    uint256 refundAmount = (p2.targetAmount * regions[regionIndex].params[2]) / 1000;
                    p2.refundAmount = refundAmount;
                    poolAmount -= refundAmount;
                }
            }
            if (round >= 3 && projects[regionIndex][round - 3].state == 3) {
                Project storage p3 = projects[regionIndex][round - 3];
                p3.state = 5;
                uint256 targetAmount = p3.targetAmount;
                uint256 _donateAmount = (targetAmount * regions[regionIndex].params[3]) / 1000;
                uint256 refundAmount = (targetAmount * (1000 - regions[regionIndex].params[2] + regions[regionIndex].params[0])) / 1000 + p3.brokerReward;
                processDonate(_donateAmount);
                p3.refundAmount += refundAmount;
                poolAmount -= (refundAmount + _donateAmount);
            }
        } else {
            p.state = 4;
            uint256 start = round >= 3 ? round - 3 : 0;
            uint16 backRound = regions[regionIndex].params[11];
            for (uint256 i = start; i < round; i++) {
                Project storage pi = projects[regionIndex][i];
                if (pi.state == 3) {
                    pi.state = 6;
                    if (i + backRound >= round) {
                        uint256 refundAmount = (pi.targetAmount * (regions[regionIndex].params[2])) / 1000;
                        pi.refundAmount = refundAmount;
                        poolAmount -= refundAmount;
                    }
                }
            }
            if (currentAmount > 0) {
                poolAmount -= currentAmount;
                uint256 bonusAmount = (poolAmount * regions[regionIndex].params[5]) / 1000;
                poolAmount -= bonusAmount;
                p.refundAmount = bonusAmount + currentAmount;
            }
            resetProjects(regionIndex, round);
        }
        regions[regionIndex].poolAmount = poolAmount;
        _addProject(regionIndex);
        regions[regionIndex].currentRound++;
    }

    function resetProjects(uint256 regionIndex, uint256 round) internal {
        uint256 length = projects[regionIndex].length;
        uint16 multiplier = regions[regionIndex].multiplier;
        uint256 period = regions[regionIndex].period;
        bool resetTime = block.timestamp > projects[regionIndex][round].startTime + period + min(RESTART_TIME_GAP, period);
        uint256 _targetAmount;
        uint256 _startTime;
        for (uint256 i = round + 1; i < length; i++) {
            Project storage p = projects[regionIndex][i];
            if (i == round + 1) {
                _targetAmount = regions[regionIndex].initAmount;
                if (resetTime) {
                    _startTime = block.timestamp;
                    p.startTime = _startTime;
                }
            } else {
                _targetAmount = roundup((_targetAmount * multiplier) / 1000, 1e18);
                if (resetTime) {
                    _startTime += period;
                    p.startTime = _startTime;
                }
            }
            p.targetAmount = _targetAmount;
            if (p.reserveAmount > 0) {
                ++p.version;
                p.reserveAmount = 0;
                p.currentAmount = 0;
                p.brokerReward = 0;
            }
        }
    }

    function pending(
        address account,
        uint256 regionIndex,
        uint256 round
    )
        public
        view
        returns (
            uint256[] memory amounts,
            uint16 state,
            uint16 version,
            bool restart
        )
    {
        amounts = new uint256[](6);
        Project storage p = projects[regionIndex][round];
        ProjectFund storage pf = projectFunds[account][regionIndex][round];
        uint256 fundAmount = pf.fund;
        amounts[5] = pf.refund;
        amounts[0] = fundAmount;
        state = p.state;
        uint256 currentAmount = p.currentAmount;
        version = p.version;
        if (pf.version == projects[regionIndex][round].version) {
            if (state == 3 && p.refundAmount > 0) {
                amounts[1] = (fundAmount * regions[regionIndex].params[2]) / 1000 - amounts[5];
            } else if (state == 4) {
                amounts[1] = fundAmount - amounts[5];
                amounts[2] = currentAmount == 0 ? 0 : ((p.refundAmount - currentAmount) * fundAmount) / currentAmount;
            } else if (state == 5) {
                amounts[1] = fundAmount - amounts[5];
                amounts[2] = (fundAmount * regions[regionIndex].params[0]) / 1000;
            } else if (state == 6) {
                amounts[1] = (fundAmount * regions[regionIndex].params[2]) / 1000 - amounts[5];
                amounts[3] = (fundAmount * (1000 - regions[regionIndex].params[2])) / regions[regionIndex].params[7];
                amounts[4] = fundAmount;
            }
            uint256 refund = getLeverageAmount(account, regionIndex, pf.reserveRefund);
            amounts[1] += refund;
            amounts[3] += refund;
            amounts[4] += pf.priorityRefund;
        } else {
            restart = true;
            uint256 refund = getLeverageAmount(account, regionIndex, pf.reserveFund + pf.reserveRefund);
            amounts[1] = refund;
            amounts[3] = refund;
            amounts[4] = (pf.reserve + pf.priorityRefund);
        }
    }

    function _harvest(
        uint256 regionIndex,
        uint256 refundAmount,
        uint256 rewardAmount,
        uint256 freeWithdrawAmount,
        uint256 priorityFundAmount
    ) internal {
        (uint256 _priorityAmount, uint256 _freeWithdrawAmount) = ICrowdAccount(crowdAccount).accountAmounts(msg.sender);
        if (priorityFundAmount > 0) {
            _priorityAmount += priorityFundAmount;
        }
        if (freeWithdrawAmount > 0) {
            _freeWithdrawAmount += freeWithdrawAmount;
        }
        uint256 amount = refundAmount + rewardAmount;
        if (amount > 0) {
            if (_freeWithdrawAmount >= amount) {
                _freeWithdrawAmount -= amount;
                IERC20(LP).safeTransfer(msg.sender, amount);
            } else {
                uint256 _feeAmount = ((amount - _freeWithdrawAmount) * regions[regionIndex].params[7]) / 1000;
                _freeWithdrawAmount = 0;
                IERC20(LP).safeTransfer(msg.sender, amount - _feeAmount);
                IERC20(LP).safeTransfer(fee, _feeAmount);
            }
        }
        ICrowdAccount(crowdAccount).setAccountAmounts(msg.sender, _priorityAmount, _freeWithdrawAmount);
    }

    function _processBrokerReward(
        address addr,
        uint256 regionIndex,
        uint256 round,
        uint16 version,
        uint256 amount
    ) internal {
        BrokerReward storage br = brokerRewards[addr][regionIndex][round];
        brokerRewardIds[addr][regionIndex].add(round);
        if (br.version == version) {
            br.amount += amount;
        } else {
            br.version = version;
            br.amount = amount;
        }
    }

    function processBrokerReward(
        address addr,
        uint256 regionIndex,
        uint256 round,
        uint16 version,
        uint256 fundAmount
    ) internal {
        uint16 used = 0;
        uint16 level = 0;
        for (uint256 i = 0; i < 45; i++) {
            (uint8 parentLevel, address head) = ICrowdAccount(crowdAccount).accountVipsHead(addr);
            if (bonus[parentLevel] > bonus[level]) {
                uint16 diff = bonus[parentLevel] - bonus[level];
                uint256 _amount = (fundAmount * diff) / 1000;
                used += diff;
                _processBrokerReward(addr, regionIndex, round, version, _amount);
                if (parentLevel == 5) break;
                level = parentLevel;
            }
            if (head == address(0)) {
                break;
            }
            addr = head;
        }
        projects[regionIndex][round].brokerReward += (fundAmount * used) / 1000;
    }

    function processDonate(uint256 amount) internal {
        IERC20(LP).safeTransfer(donate, amount);
    }

    function harvestAll(uint256 regionIndex, uint256[] calldata roundIds) external {
        (uint256 refundAmount, uint256 rewardAmount, uint256 freeWithdrawAmount, uint256 priorityFundAmount) = (0, 0, 0, 0);
        for (uint256 i = 0; i < roundIds.length; i++) {
            if (harvestableIds[msg.sender][regionIndex].contains(roundIds[i])) {
                (uint256[] memory amounts, uint16 state, uint16 version, bool restart) = pending(msg.sender, regionIndex, roundIds[i]);
                refundAmount += amounts[1];
                rewardAmount += amounts[2];
                freeWithdrawAmount += amounts[3];
                priorityFundAmount += amounts[4];
                if (state > 3) {
                    harvestableIds[msg.sender][regionIndex].remove(roundIds[i]);
                } else {
                    ProjectFund storage pf = projectFunds[msg.sender][regionIndex][roundIds[i]];
                    uint256 refund = amounts[1] - getLeverageAmount(msg.sender, regionIndex, pf.reserveRefund);
                    pf.reserveRefund = 0;
                    pf.priorityRefund = 0;
                    if (restart == true) {
                        pf.version = version;
                        pf.fund = 0;
                        pf.refund = 0;
                        pf.reserve = 0;
                        pf.reserveFund = 0;
                    } else {
                        pf.refund += refund;
                    }
                }
            }
        }
        if (refundAmount > 0 || priorityFundAmount > 0) _harvest(regionIndex, refundAmount, rewardAmount, freeWithdrawAmount, priorityFundAmount);
    }

    function pendingForBrokerReward(
        address account,
        uint256 regionIndex,
        uint256[] calldata roundIds
    ) public view returns (uint256 amount, uint16[] memory states) {
        states = new uint16[](roundIds.length);
        for (uint256 i = 0; i < roundIds.length; i++) {
            uint256 round = roundIds[i];
            uint16 version = projects[regionIndex][round].version;
            uint16 state = projects[regionIndex][round].state;
            states[i] = state;
            if (state == 5 && brokerRewards[account][regionIndex][round].version == version && brokerRewardIds[account][regionIndex].contains(round)) {
                amount += brokerRewards[account][regionIndex][round].amount;
            }
        }
    }

    function withdrawBrokerReward(uint256 regionIndex, uint256[] calldata roundIds) external {
        (uint256 amount, uint16[] memory states) = pendingForBrokerReward(msg.sender, regionIndex, roundIds);
        for (uint256 i = 0; i < roundIds.length; i++) {
            if (states[i] > 3) brokerRewardIds[msg.sender][regionIndex].remove(roundIds[i]);
        }
        if (amount > 0) _harvest(regionIndex, 0, amount, 0, 0);
    }

    function getRegionCount() external view returns (uint256) {
        return regions.length;
    }

    function getProjectCount(uint256 _regionIndex) external view returns (uint256) {
        return projects[_regionIndex].length;
    }

    function getProjects(
        uint256 regionIndex,
        uint256 offset,
        uint256 size
    ) external view returns (Project[] memory projectList) {
        uint256 length = projects[regionIndex].length;
        require(offset + size <= length, "out of bound");
        projectList = new Project[](size);
        for (uint256 i = 0; i < size; i++) {
            projectList[i] = projects[regionIndex][offset + i];
        }
    }

    function getProjectIds(address account, uint256 regionIndex) external view returns (uint256[] memory) {
        return projectIds[account][regionIndex];
    }

    function getHarvestableIds(address account, uint256 regionIndex) external view returns (uint256[] memory) {
        return harvestableIds[account][regionIndex].values();
    }

    function getBrokerRewardIds(address account, uint256 regionIndex) external view returns (uint256[] memory) {
        return brokerRewardIds[account][regionIndex].values();
    }

    function getMaxAmountPerTime(uint256 regionIndex, uint256 targetAmount) public view returns (uint256) {
        uint256 max = (targetAmount * regions[regionIndex].params[9]) / 1000;
        uint256 maxFundAmount = uint256(regions[regionIndex].params[10]) * 1e18;
        return max > maxFundAmount ? max : maxFundAmount;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function roundup(uint256 a, uint256 m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }

    function getLeverageAmount(
        address addr,
        uint256 regionIndex,
        uint256 amount
    ) internal view returns (uint256) {
        return leverageMap[addr] == true ? (amount * (1000 - regions[regionIndex].params[2])) / 1000 : amount;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICrowdAccount {
    function accountVips(address addr) external returns (uint8 vips);

    function accountVipsHead(address addr) external view returns (uint8 vips, address head);

    function priorityFundAmount(address addr) external view returns (uint256);

    function setPriorityFundAmount(address addr, uint256 amount) external;

    function accountAmounts(address addr) external view returns (uint256 priorityAmount, uint256 freeWithdrawAmount);

    function setAccountAmounts(
        address addr,
        uint256 priorityAmount,
        uint256 freeWithdrawAmount
    ) external;
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