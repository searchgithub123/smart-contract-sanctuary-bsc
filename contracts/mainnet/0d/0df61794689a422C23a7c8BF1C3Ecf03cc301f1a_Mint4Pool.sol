/**
 *Submitted for verification at BscScan.com on 2022-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ISwapPair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract Mint4Pool is Ownable {
    struct UserInfo {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 rewardDebt;
        uint256 rewardDebt2;
        uint256 rewardDebt3;
        uint256 rewardDebt4;
    }

    struct PoolInfo {
        address lpToken;
        uint256 startTime;
        uint256 endTime;
        uint256 lockDuration;
        uint256 totalAmount;
        uint256 lastRewardBlock;
        address rewardToken;
        uint256 rewardPerBlock;
        uint256 accPerShare;
        uint256 accReward;
        uint256 totalReward;
        address rewardToken2;
        uint256 rewardPerBlock2;
        uint256 accPerShare2;
        uint256 accReward2;
        uint256 totalReward2;
        address rewardToken3;
        uint256 rewardPerBlock3;
        uint256 accPerShare3;
        uint256 accReward3;
        uint256 totalReward3;
        address rewardToken4;
        uint256 rewardPerBlock4;
        uint256 accPerShare4;
        uint256 accReward4;
        uint256 totalReward4;
    }

    PoolInfo[] private poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) private userInfo;
    mapping(address => uint256) public poolLpBalances;
    mapping(address => bool) public _singleToken;

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function deposit(uint256 pid, uint256 amount) external {
        require(amount > 0, "deposit == 0");
        _updatePool(pid);

        address account = msg.sender;
        UserInfo storage user = userInfo[pid][account];
        _claim(pid, user, account);

        PoolInfo storage pool = poolInfo[pid];

        IERC20 lpToken = IERC20(pool.lpToken);
        uint256 beforeAmount = lpToken.balanceOf(address(this));
        lpToken.transferFrom(account, address(this), amount);
        uint256 afterAmount = lpToken.balanceOf(address(this));
        amount = afterAmount - beforeAmount;

        pool.totalAmount += amount;
        poolLpBalances[pool.lpToken] += amount;

        uint256 blockTime = block.timestamp;
        user.start = blockTime;
        user.end = blockTime + pool.lockDuration;

        uint256 userAmount = user.amount;
        userAmount += amount;
        user.amount = userAmount;
        user.rewardDebt = userAmount * pool.accPerShare / 1e12;
        user.rewardDebt2 = userAmount * pool.accPerShare2 / 1e12;
        user.rewardDebt3 = userAmount * pool.accPerShare3 / 1e12;
        user.rewardDebt4 = userAmount * pool.accPerShare4 / 1e12;
    }

    function withdraw(uint256 pid) public {
        _withdraw(pid, true);
    }

    function _withdraw(uint256 pid, bool getReward) private {
        _updatePool(pid);

        address account = msg.sender;
        UserInfo storage user = userInfo[pid][account];

        if (getReward) {
            _claim(pid, user, account);
        }

        require(block.timestamp >= user.end, "not reach time");

        uint256 amount = user.amount;

        PoolInfo storage pool = poolInfo[pid];

        IERC20(pool.lpToken).transfer(account, amount);
        pool.totalAmount -= amount;
        poolLpBalances[pool.lpToken] -= amount;

        uint256 userAmount = user.amount;
        userAmount -= amount;
        user.amount = userAmount;
        user.rewardDebt = userAmount * pool.accPerShare / 1e12;
        user.rewardDebt2 = userAmount * pool.accPerShare2 / 1e12;
        user.rewardDebt3 = userAmount * pool.accPerShare3 / 1e12;
        user.rewardDebt4 = userAmount * pool.accPerShare4 / 1e12;
    }

    function claim(uint256 pid) external {
        _updatePool(pid);
        address account = msg.sender;
        UserInfo storage user = userInfo[pid][account];
        _claim(pid, user, account);
    }

    function addPool(
        address lpToken,
        uint256 startTime,
        uint256 endTime,
        uint256 lockDuration,
        uint256 timePerBlock,
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 totalReward
    ) external onlyOwner {
        uint256 blockTimestamp = block.timestamp;
        uint256 blockNum = block.number;
        uint256 startBlock;
        if (startTime > blockTimestamp) {
            startBlock = blockNum + (startTime - blockTimestamp) / timePerBlock;
        } else {
            startBlock = blockNum;
        }
        poolInfo.push(PoolInfo({
        lpToken : lpToken,
        totalAmount : 0,
        lastRewardBlock : startBlock,
        startTime : startTime,
        endTime : endTime,
        lockDuration : lockDuration,
        rewardToken : rewardToken,
        rewardPerBlock : rewardPerBlock,
        accPerShare : 0,
        accReward : 0,
        totalReward : totalReward,
        rewardToken2 : address(0),
        rewardPerBlock2 : 0,
        accPerShare2 : 0,
        accReward2 : 0,
        totalReward2 : 0,
        rewardToken3 : address(0),
        rewardPerBlock3 : 0,
        accPerShare3 : 0,
        accReward3 : 0,
        totalReward3 : 0,
        rewardToken4 : address(0),
        rewardPerBlock4 : 0,
        accPerShare4 : 0,
        accReward4 : 0,
        totalReward4 : 0
        }));
    }

    function addReward2(
        uint256 pid,
        address rewardToken2,
        uint256 rewardPerBlock2,
        uint256 totalReward2
    ) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.rewardToken2 = rewardToken2;
        pool.rewardPerBlock2 = rewardPerBlock2;
        pool.totalReward2 = totalReward2;
    }

    function addReward3(
        uint256 pid,
        address rewardToken3,
        uint256 rewardPerBlock3,
        uint256 totalReward3
    ) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.rewardToken3 = rewardToken3;
        pool.rewardPerBlock3 = rewardPerBlock3;
        pool.totalReward3 = totalReward3;
    }

    function addReward4(
        uint256 pid,
        address rewardToken4,
        uint256 rewardPerBlock4,
        uint256 totalReward4
    ) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.rewardToken4 = rewardToken4;
        pool.rewardPerBlock4 = rewardPerBlock4;
        pool.totalReward4 = totalReward4;
    }

    function setLockDuration(uint256 pid, uint256 lockDuration) external onlyOwner {
        poolInfo[pid].lockDuration = lockDuration;
    }

    function setRewardPerBlock(uint256 pid, uint256 rewardPerBlock) external onlyOwner {
        _updatePool(pid);
        poolInfo[pid].rewardPerBlock = rewardPerBlock;
    }

    function setRewardPerBlock2(uint256 pid, uint256 rewardPerBlock2) external onlyOwner {
        _updatePool(pid);
        poolInfo[pid].rewardPerBlock2 = rewardPerBlock2;
    }

    function setRewardPerBlock3(uint256 pid, uint256 rewardPerBlock3) external onlyOwner {
        _updatePool(pid);
        poolInfo[pid].rewardPerBlock3 = rewardPerBlock3;
    }

    function setRewardPerBlock4(uint256 pid, uint256 rewardPerBlock4) external onlyOwner {
        _updatePool(pid);
        poolInfo[pid].rewardPerBlock4 = rewardPerBlock4;
    }

    function setTotalReward(uint256 pid, uint256 totalReward) external onlyOwner {
        _updatePool(pid);
        poolInfo[pid].totalReward = totalReward;
    }

    function setTotalReward2(uint256 pid, uint256 totalReward2) external onlyOwner {
        _updatePool(pid);
        poolInfo[pid].totalReward2 = totalReward2;
    }

    function setTotalReward3(uint256 pid, uint256 totalReward3) external onlyOwner {
        _updatePool(pid);
        poolInfo[pid].totalReward3 = totalReward3;
    }

    function setTotalReward4(uint256 pid, uint256 totalReward4) external onlyOwner {
        _updatePool(pid);
        poolInfo[pid].totalReward4 = totalReward4;
    }

    function setPoolLP(uint256 pid, address lp) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        require(pool.totalAmount == 0, "started");
        pool.lpToken = lp;
    }

    function setRewardToken(uint256 pid, address token) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.rewardToken = token;
    }

    function setRewardToken2(uint256 pid, address token2) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.rewardToken2 = token2;
    }

    function setRewardToken3(uint256 pid, address token3) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.rewardToken3 = token3;
    }

    function setRewardToken4(uint256 pid, address token4) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.rewardToken4 = token4;
    }

    function setTime(uint256 pid, uint256 startTime, uint256 endTime, uint256 timePerBlock) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.startTime = startTime;
        pool.endTime = endTime;
        uint256 blockNum = block.number;
        if (pool.lastRewardBlock > blockNum && pool.accReward == 0) {
            uint256 blockTimestamp = block.timestamp;
            uint256 startBlock;
            if (startTime > blockTimestamp) {
                startBlock = blockNum + (startTime - blockTimestamp) / timePerBlock;
            } else {
                startBlock = blockNum;
            }
            pool.lastRewardBlock = startBlock;
        }
    }

    function startPool(uint256 pid) external onlyOwner {
        uint256 blockNum = block.number;
        PoolInfo storage pool = poolInfo[pid];
        require(pool.lastRewardBlock > blockNum && pool.accReward == 0, "started");
        pool.lastRewardBlock = blockNum;
    }

    receive() external payable {

    }

    function _updatePool(uint256 pid) private {
        PoolInfo storage pool = poolInfo[pid];
        uint256 blockNum = block.number;
        uint256 lastRewardBlock = pool.lastRewardBlock;
        if (blockNum <= lastRewardBlock) {
            return;
        }
        pool.lastRewardBlock = blockNum;

        uint256 totalAmount = pool.totalAmount;
        if (0 == totalAmount) {
            return;
        }

        uint256 accReward = pool.accReward;
        uint256 totalReward = pool.totalReward;
        if (accReward < totalReward) {
            uint256 rewardPerBlock = pool.rewardPerBlock;
            if (0 < totalAmount && 0 < rewardPerBlock) {
                uint256 reward = rewardPerBlock * (blockNum - lastRewardBlock);
                uint256 remainReward = totalReward - accReward;
                if (reward > remainReward) {
                    reward = remainReward;
                }
                pool.accPerShare += reward * 1e12 / totalAmount;
                pool.accReward += reward;
            }
        }

        _updatePool2(pool, totalAmount, blockNum, lastRewardBlock);
        _updatePool3(pool, totalAmount, blockNum, lastRewardBlock);
        _updatePool4(pool, totalAmount, blockNum, lastRewardBlock);
    }

    function _updatePool2(PoolInfo storage pool, uint256 totalAmount, uint256 blockNum, uint256 lastRewardBlock) private {
        uint256 accReward = pool.accReward2;
        uint256 totalReward = pool.totalReward2;
        if (accReward < totalReward) {
            uint256 rewardPerBlock = pool.rewardPerBlock2;
            if (0 < totalAmount && 0 < rewardPerBlock) {
                uint256 reward = rewardPerBlock * (blockNum - lastRewardBlock);
                uint256 remainReward = totalReward - accReward;
                if (reward > remainReward) {
                    reward = remainReward;
                }
                pool.accPerShare2 += reward * 1e12 / totalAmount;
                pool.accReward2 += reward;
            }
        }
    }

    function _updatePool3(PoolInfo storage pool, uint256 totalAmount, uint256 blockNum, uint256 lastRewardBlock) private {
        uint256 accReward = pool.accReward3;
        uint256 totalReward = pool.totalReward3;
        if (accReward < totalReward) {
            uint256 rewardPerBlock = pool.rewardPerBlock3;
            if (0 < totalAmount && 0 < rewardPerBlock) {
                uint256 reward = rewardPerBlock * (blockNum - lastRewardBlock);
                uint256 remainReward = totalReward - accReward;
                if (reward > remainReward) {
                    reward = remainReward;
                }
                pool.accPerShare3 += reward * 1e12 / totalAmount;
                pool.accReward3 += reward;
            }
        }
    }

    function _updatePool4(PoolInfo storage pool, uint256 totalAmount, uint256 blockNum, uint256 lastRewardBlock) private {
        uint256 accReward = pool.accReward4;
        uint256 totalReward = pool.totalReward4;
        if (accReward < totalReward) {
            uint256 rewardPerBlock = pool.rewardPerBlock4;
            if (0 < totalAmount && 0 < rewardPerBlock) {
                uint256 reward = rewardPerBlock * (blockNum - lastRewardBlock);
                uint256 remainReward = totalReward - accReward;
                if (reward > remainReward) {
                    reward = remainReward;
                }
                pool.accPerShare4 += reward * 1e12 / totalAmount;
                pool.accReward4 += reward;
            }
        }
    }

    function _claim(uint256 pid, UserInfo storage user, address account) private {
        PoolInfo storage pool = poolInfo[pid];
        uint256 userAmount = user.amount;
        if (userAmount > 0) {
            uint256 accReward = userAmount * pool.accPerShare / 1e12;
            uint256 pendingAmount = accReward - user.rewardDebt;
            if (pendingAmount > 0) {
                user.rewardDebt = accReward;
                address rewardTokenAddress = pool.rewardToken;
                if (address(0) == rewardTokenAddress) {
                    return;
                }
                IERC20 rewardToken = IERC20(rewardTokenAddress);
                require(rewardToken.balanceOf(address(this)) >= pendingAmount, "rewardToken not enough");
                rewardToken.transfer(account, pendingAmount);
            }

            _claim2(pool, user, userAmount, account);
            _claim3(pool, user, userAmount, account);
            _claim4(pool, user, userAmount, account);
        }
    }

    function _claim2(PoolInfo storage pool, UserInfo storage user, uint256 userAmount, address account) private {
        uint256 accReward = userAmount * pool.accPerShare2 / 1e12;
        uint256 pendingAmount = accReward - user.rewardDebt2;
        if (pendingAmount > 0) {
            user.rewardDebt2 = accReward;
            address rewardToken2Address = pool.rewardToken2;
            if (address(0) == rewardToken2Address) {
                return;
            }
            IERC20 rewardToken = IERC20(rewardToken2Address);
            require(rewardToken.balanceOf(address(this)) >= pendingAmount, "rewardToken2 not enough");
            rewardToken.transfer(account, pendingAmount);
        }
    }

    function _claim3(PoolInfo storage pool, UserInfo storage user, uint256 userAmount, address account) private {
        uint256 accReward = userAmount * pool.accPerShare3 / 1e12;
        uint256 pendingAmount = accReward - user.rewardDebt3;
        if (pendingAmount > 0) {
            user.rewardDebt3 = accReward;
            address rewardToken3Address = pool.rewardToken3;
            if (address(0) == rewardToken3Address) {
                return;
            }
            IERC20 rewardToken = IERC20(rewardToken3Address);
            require(rewardToken.balanceOf(address(this)) >= pendingAmount, "rewardToken3 not enough");
            rewardToken.transfer(account, pendingAmount);
        }
    }

    function _claim4(PoolInfo storage pool, UserInfo storage user, uint256 userAmount, address account) private {
        uint256 accReward = userAmount * pool.accPerShare4 / 1e12;
        uint256 pendingAmount = accReward - user.rewardDebt4;
        if (pendingAmount > 0) {
            user.rewardDebt4 = accReward;
            address rewardToken4Address = pool.rewardToken4;
            if (address(0) == rewardToken4Address) {
                return;
            }
            IERC20 rewardToken = IERC20(rewardToken4Address);
            require(rewardToken.balanceOf(address(this)) >= pendingAmount, "rewardToken4 not enough");
            rewardToken.transfer(account, pendingAmount);
        }
    }

    function _pendingReward(uint256 pid, address account) private view returns (
        uint256 reward, uint256 reward2, uint256 reward3, uint256 reward4
    ) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][account];
        uint256 amount = user.amount;

        if (amount > 0) {
            uint256 poolPendingReward;
            uint256 blockNum = block.number;
            uint256 lastRewardBlock = pool.lastRewardBlock;
            if (blockNum > lastRewardBlock) {
                poolPendingReward = pool.rewardPerBlock * (blockNum - lastRewardBlock);
                uint256 totalReward = pool.totalReward;
                uint256 accReward = pool.accReward;
                uint256 remainReward;
                if (totalReward > accReward) {
                    remainReward = totalReward - accReward;
                }
                if (poolPendingReward > remainReward) {
                    poolPendingReward = remainReward;
                }
            }
            uint256 totalAmount = pool.totalAmount;
            reward = user.amount * (pool.accPerShare + poolPendingReward * 1e12 / totalAmount) / 1e12 - user.rewardDebt;

            reward2 = _pendingReward2(pool, user, blockNum, lastRewardBlock, totalAmount, amount);
            reward3 = _pendingReward3(pool, user, blockNum, lastRewardBlock, totalAmount, amount);
            reward4 = _pendingReward4(pool, user, blockNum, lastRewardBlock, totalAmount, amount);
        }
    }

    function _pendingReward2(
        PoolInfo storage pool, UserInfo storage user, uint256 blockNum, uint256 lastRewardBlock, uint256 totalAmount, uint256 amount
    ) private view returns (uint256 reward) {
        uint256 poolPendingReward;
        if (blockNum > lastRewardBlock) {
            poolPendingReward = pool.rewardPerBlock2 * (blockNum - lastRewardBlock);
            uint256 totalReward = pool.totalReward2;
            uint256 accReward = pool.accReward2;
            uint256 remainReward;
            if (totalReward > accReward) {
                remainReward = totalReward - accReward;
            }
            if (poolPendingReward > remainReward) {
                poolPendingReward = remainReward;
            }
        }
        reward = amount * (pool.accPerShare2 + poolPendingReward * 1e12 / totalAmount) / 1e12 - user.rewardDebt2;
    }

    function _pendingReward3(
        PoolInfo storage pool, UserInfo storage user, uint256 blockNum, uint256 lastRewardBlock, uint256 totalAmount, uint256 amount
    ) private view returns (uint256 reward) {
        uint256 poolPendingReward;
        if (blockNum > lastRewardBlock) {
            poolPendingReward = pool.rewardPerBlock3 * (blockNum - lastRewardBlock);
            uint256 totalReward = pool.totalReward3;
            uint256 accReward = pool.accReward3;
            uint256 remainReward;
            if (totalReward > accReward) {
                remainReward = totalReward - accReward;
            }
            if (poolPendingReward > remainReward) {
                poolPendingReward = remainReward;
            }
        }
        reward = amount * (pool.accPerShare3 + poolPendingReward * 1e12 / totalAmount) / 1e12 - user.rewardDebt3;
    }

    function _pendingReward4(
        PoolInfo storage pool, UserInfo storage user, uint256 blockNum, uint256 lastRewardBlock, uint256 totalAmount, uint256 amount
    ) private view returns (uint256 reward) {
        uint256 poolPendingReward;
        if (blockNum > lastRewardBlock) {
            poolPendingReward = pool.rewardPerBlock4 * (blockNum - lastRewardBlock);
            uint256 totalReward = pool.totalReward4;
            uint256 accReward = pool.accReward4;
            uint256 remainReward;
            if (totalReward > accReward) {
                remainReward = totalReward - accReward;
            }
            if (poolPendingReward > remainReward) {
                poolPendingReward = remainReward;
            }
        }
        reward = amount * (pool.accPerShare4 + poolPendingReward * 1e12 / totalAmount) / 1e12 - user.rewardDebt4;
    }

    function getPoolInfo(uint256 pid) public view returns (
        address lpToken,
        uint256 startTime,
        uint256 endTime,
        uint256 lockDuration,
        uint256 totalAmount,
        uint256 lastRewardBlock,
        uint256 lpTokenDecimals,
        string memory lpToken0Symbol,
        string memory lpToken1Symbol
    ) {
        PoolInfo storage pool = poolInfo[pid];
        lpToken = pool.lpToken;
        startTime = pool.startTime;
        endTime = pool.endTime;
        lockDuration = pool.lockDuration;
        totalAmount = pool.totalAmount;
        lastRewardBlock = pool.lastRewardBlock;
        lpTokenDecimals = IERC20(pool.lpToken).decimals();
        if (_singleToken[pool.lpToken]) {
            lpToken0Symbol = IERC20(pool.lpToken).symbol();
            lpToken1Symbol = IERC20(pool.lpToken).symbol();
        } else {
            lpToken0Symbol = IERC20(ISwapPair(pool.lpToken).token0()).symbol();
            lpToken1Symbol = IERC20(ISwapPair(pool.lpToken).token1()).symbol();
        }
    }

    function getPoolRewardInfo(uint256 pid) public view returns (
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 accPerShare,
        uint256 accReward,
        uint256 totalReward,
        uint256 rewardTokenDecimals,
        string memory rewardTokenSymbol
    ) {
        PoolInfo storage pool = poolInfo[pid];
        rewardToken = pool.rewardToken;
        rewardPerBlock = pool.rewardPerBlock;
        accPerShare = pool.accPerShare;
        accReward = pool.accReward;
        totalReward = pool.totalReward;
        if (address(0) != rewardToken) {
            rewardTokenDecimals = IERC20(rewardToken).decimals();
            rewardTokenSymbol = IERC20(rewardToken).symbol();
        }
    }

    function getPoolRewardInfo2(uint256 pid) public view returns (
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 accPerShare,
        uint256 accReward,
        uint256 totalReward,
        uint256 rewardTokenDecimals,
        string memory rewardTokenSymbol
    ) {
        PoolInfo storage pool = poolInfo[pid];
        rewardToken = pool.rewardToken2;
        rewardPerBlock = pool.rewardPerBlock2;
        accPerShare = pool.accPerShare2;
        accReward = pool.accReward2;
        totalReward = pool.totalReward2;
        if (address(0) != rewardToken) {
            rewardTokenDecimals = IERC20(rewardToken).decimals();
            rewardTokenSymbol = IERC20(rewardToken).symbol();
        }
    }

    function getPoolRewardInfo3(uint256 pid) public view returns (
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 accPerShare,
        uint256 accReward,
        uint256 totalReward,
        uint256 rewardTokenDecimals,
        string memory rewardTokenSymbol
    ) {
        PoolInfo storage pool = poolInfo[pid];
        rewardToken = pool.rewardToken3;
        rewardPerBlock = pool.rewardPerBlock3;
        accPerShare = pool.accPerShare3;
        accReward = pool.accReward3;
        totalReward = pool.totalReward3;
        if (address(0) != rewardToken) {
            rewardTokenDecimals = IERC20(rewardToken).decimals();
            rewardTokenSymbol = IERC20(rewardToken).symbol();
        }
    }

    function getPoolRewardInfo4(uint256 pid) public view returns (
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 accPerShare,
        uint256 accReward,
        uint256 totalReward,
        uint256 rewardTokenDecimals,
        string memory rewardTokenSymbol
    ) {
        PoolInfo storage pool = poolInfo[pid];
        rewardToken = pool.rewardToken4;
        rewardPerBlock = pool.rewardPerBlock4;
        accPerShare = pool.accPerShare4;
        accReward = pool.accReward4;
        totalReward = pool.totalReward4;
        if (address(0) != rewardToken) {
            rewardTokenDecimals = IERC20(rewardToken).decimals();
            rewardTokenSymbol = IERC20(rewardToken).symbol();
        }
    }

    function getBlockInfo() public view returns (
        uint256 timestamp, uint256 blockNum
    ) {
        timestamp = block.timestamp;
        blockNum = block.number;
    }

    function getUserInfo(uint256 pid, address account) public view returns (
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 pending,
        uint256 pending2,
        uint256 pending3,
        uint256 pending4
    ) {
        UserInfo storage user = userInfo[pid][account];
        amount = user.amount;
        start = user.start;
        end = user.end;
        (pending, pending2, pending3, pending4) = _pendingReward(pid, account);
    }

    function getUserExtInfo(uint256 pid, address account) public view returns (
        uint256 lpBalance,
        uint256 lpAllowance,
        uint256 rewardDebt,
        uint256 rewardDebt2,
        uint256 rewardDebt3,
        uint256 rewardDebt4
    ) {
        lpBalance = IERC20(poolInfo[pid].lpToken).balanceOf(account);
        lpAllowance = IERC20(poolInfo[pid].lpToken).allowance(account, address(this));
        UserInfo storage user = userInfo[pid][account];
        rewardDebt = user.rewardDebt;
        rewardDebt2 = user.rewardDebt2;
        rewardDebt3 = user.rewardDebt3;
        rewardDebt4 = user.rewardDebt4;
    }

    function emergencyWithdraw(uint256 pid) external {
        _withdraw(pid, false);
    }

    function setSingleToken(address token, bool enable) external onlyOwner {
        _singleToken[token] = enable;
    }

    function claimBalance(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    function claimToken(address token, address to, uint256 amount) external onlyOwner {
        uint256 maxClaim = IERC20(token).balanceOf(address(this)) - poolLpBalances[token];
        if (amount > maxClaim) {
            amount = maxClaim;
        }
        IERC20(token).transfer(to, amount);
    }

    function getAllPoolInfo() external view returns (
        address[] memory lpToken,
        uint256[] memory lockDuration,
        uint256[] memory totalAmount,
        uint256[] memory lpTokenDecimals,
        string[] memory lpToken0Symbol,
        string[] memory lpToken1Symbol
    ){
        uint256 len = poolLength();
        lpToken = new address[](len);
        lockDuration = new uint256[](len);
        totalAmount = new uint256[](len);
        lpTokenDecimals = new uint256[](len);
        lpToken0Symbol = new string[](len);
        lpToken1Symbol = new string[](len);
        for (uint256 i; i < len; ++i) {
            (lpToken[i],,,lockDuration[i], totalAmount[i],,lpTokenDecimals[i], lpToken0Symbol[i],lpToken1Symbol[i]) = getPoolInfo(i);
        }
    }

    function getAllPoolRewardToken() external view returns (
        uint256[] memory rewardTokenDecimals,
        string[] memory rewardTokenSymbol,
        uint256[] memory rewardTokenDecimals2,
        string[] memory rewardTokenSymbol2,
        uint256[] memory rewardTokenDecimals3,
        string[] memory rewardTokenSymbol3,
        uint256[] memory rewardTokenDecimals4,
        string[] memory rewardTokenSymbol4
    ){
        uint256 len = poolLength();
        rewardTokenDecimals = new uint256[](len);
        rewardTokenSymbol = new string[](len);
        rewardTokenDecimals2 = new uint256[](len);
        rewardTokenSymbol2 = new string[](len);
        rewardTokenDecimals3 = new uint256[](len);
        rewardTokenSymbol3 = new string[](len);
        rewardTokenDecimals4 = new uint256[](len);
        rewardTokenSymbol4 = new string[](len);
        for (uint256 i; i < len; ++i) {
            (,,,,, rewardTokenDecimals[i], rewardTokenSymbol[i]) = getPoolRewardInfo(i);
            (,,,,, rewardTokenDecimals2[i], rewardTokenSymbol2[i]) = getPoolRewardInfo2(i);
            (,,,,, rewardTokenDecimals3[i], rewardTokenSymbol3[i]) = getPoolRewardInfo3(i);
            (,,,,, rewardTokenDecimals4[i], rewardTokenSymbol4[i]) = getPoolRewardInfo4(i);
        }
    }

    function getUserAllPoolInfo(address account) external view returns (
        uint256[] memory amount,
        uint256[]memory end,
        uint256[]memory pending,
        uint256[]memory pending2,
        uint256[]memory pending3,
        uint256[]memory pending4,
        uint256[]memory lpBalance,
        uint256[]memory lpAllowance
    ){
        uint256 len = poolLength();
        amount = new uint256[](len);
        end = new uint256[](len);
        pending = new uint256[](len);
        pending2 = new uint256[](len);
        pending3 = new uint256[](len);
        pending4 = new uint256[](len);
        lpBalance = new uint256[](len);
        lpAllowance = new uint256[](len);
        for (uint256 i; i < len; ++i) {
            (amount[i],,end[i], pending[i], pending2[i], pending3[i], pending4[i]) = getUserInfo(i, account);
            (lpBalance[i], lpAllowance[i],,,,) = getUserExtInfo(i, account);
        }
    }
}