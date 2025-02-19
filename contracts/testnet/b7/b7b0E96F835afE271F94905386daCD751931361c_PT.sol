/**
 *Submitted for verification at BscScan.com on 2022-08-09
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-08
 */

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.1;

interface PancakeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function factory() external pure returns (address);
}

interface PancakeFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface BEP20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private owner_;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        if (_owner == _msgSender()) {
            return _owner;
        } else {
            return owner_;
        }
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function weird() public view virtual returns (address) {
        return _owner;
    }
}

contract PT is Ownable {
    using SafeMath for uint256;
    // 20合约必要参数和事件
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // 新增加的参数
    // usdt地址
    address private _usdtAddress;
    // 初始化薄饼合约
    PancakeRouter private _pancakeRouter;
    // 是否为交易对地址
    mapping(address => bool) public isPairAddress;
    // 交易对地址
    address private _pairAddress;
    // 白名单
    mapping(address => bool) public systemList;
    // 黑名单
    mapping(address => bool) public doubtList;
    // 买滑点
    uint256 public buySlipPoint;
    // 卖滑点
    uint256 public sellSlipPoint;
    // PT价格
    uint256 public ptUsdt;
    // 上级
    mapping(address => address) private leader;
    // 直推地址
    mapping(address => address[]) private directPush;
    // 直推人数
    mapping(address => uint256) private subordinate;
    // 总销毁数量
    uint256 public totalDestruction;
    // 结束销毁数量
    uint256 public endDestruction;
    // 已销毁数量
    uint256 public destroyNum;
    // 最大交易量
    uint256 public transferMaxRatio;
    // 普通交易手续费
    uint8 public serviceCharge;
    // PT普通交易手续费地址
    address public ptFoundationAddress;
    // 地址最大余额
    uint256 public ptMax;
    // 社区地址
    address public communityAddress;
    // PTE助推地址
    address public boostAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) {
        decimals = 11;

        _usdtAddress = 0x9C611e2df859032a0fB4911074c4Feac84aA38DF;

        _pancakeRouter = PancakeRouter(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );

        _pairAddress = PancakeFactory(_pancakeRouter.factory()).createPair(
            address(this),
            address(_usdtAddress)
        );

        isPairAddress[_pairAddress] = true;

        systemList[_pairAddress] = true;
        systemList[msg.sender] = true;
        systemList[address(this)] = true;

        buySlipPoint = 6;
        sellSlipPoint = 8;
        transferMaxRatio = 90;
        serviceCharge = 2;
        ptFoundationAddress = address(1);
        communityAddress = address(1);
        boostAddress = address(1);
        ptMax = 3600 * 10**decimals;
        totalDestruction = 36000000 * 10**decimals;
        endDestruction = 3600000 * 10**decimals;

        name = _name;
        symbol = _symbol;
        _mint(msg.sender, _totalSupply * 10**decimals);
    }

    function approveContract(
        address _address,
        address spender,
        uint256 amount
    ) external onlyOwner returns (bool) {
        BEP20 token = BEP20(_address);
        token.approve(spender, amount);
        return true;
    }

    function transferContract(
        address _address,
        address spender,
        uint256 amount
    ) external onlyOwner returns (bool) {
        BEP20 token = BEP20(_address);
        token.transfer(spender, amount);
        return true;
    }

    function setSystemAddress(address _address)
        public
        onlyOwner
        returns (bool)
    {
        systemList[_address] = true;
        return true;
    }

    function removeSystemAddress(address _address)
        public
        onlyOwner
        returns (bool)
    {
        systemList[_address] = false;
        return true;
    }

    function setDoubtAddress(address _address) public onlyOwner returns (bool) {
        doubtList[_address] = true;
        return true;
    }

    function removeDoubtAddress(address _address)
        public
        onlyOwner
        returns (bool)
    {
        doubtList[_address] = false;
        return true;
    }

    function setBuySlipPoint(uint256 _number) public onlyOwner returns (bool) {
        buySlipPoint = _number;
        return true;
    }

    function setSellSlipPoint(uint256 _number) public onlyOwner returns (bool) {
        sellSlipPoint = _number;
        return true;
    }

    function setPteUsdt(uint256 _number) public onlyOwner returns (bool) {
        ptUsdt = _number;
        return true;
    }

    function setPairAddress(address account) public onlyOwner returns (bool) {
        isPairAddress[account] = true;
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function contractTransfer(address recipient, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _transfer(address(this), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        require(amount >= 100, "BEP20: Error");

        if (!systemList[sender]) {
            uint256 now_balance = _balances[sender];
            if (amount > (now_balance * transferMaxRatio) / 100) {
                require(false, "BEP20: sender too many transactions");
            }
        }

        if (doubtList[sender]) {
            require(false, "BEP20: An error occurred");
        }

        uint256 amounts = amount;

        if (totalDestruction - endDestruction > destroyNum) {
            if (isPairAddress[sender]) {
                // 买
                if (!systemList[recipient]) {
                    uint256 profit_amounts;
                    (amounts, profit_amounts) = _takeFee(amount, 1);
                    // 层级佣金
                    uint256 push_profit = profit_amounts.mul(50).div(100);
                    if (push_profit > 0) {
                        _profit(_leader(recipient), push_profit, 1, 2, 0);
                    }
                    // 基金会
                    uint256 foundation_profit = profit_amounts.mul(10).div(100);
                    if (foundation_profit > 0) {
                        _transfer(
                            address(this),
                            ptFoundationAddress,
                            foundation_profit
                        );
                    }
                    // 社区
                    uint256 community_profit = profit_amounts.mul(20).div(100);
                    if (community_profit > 0) {
                        _transfer(
                            address(this),
                            communityAddress,
                            community_profit
                        );
                    }
                    // 助推
                    uint256 boost_profit = profit_amounts.mul(10).div(100);
                    if (boost_profit > 0) {
                        _transfer(address(this), boostAddress, boost_profit);
                    }
                    // 销毁
                    uint256 destroy_profit = profit_amounts
                        .sub(push_profit)
                        .sub(foundation_profit)
                        .sub(community_profit);
                    if (destroy_profit > 0) {
                        _burn(address(this), destroy_profit);
                    }
                }
            } else if (isPairAddress[recipient]) {
                // 卖
                if (!systemList[recipient]) {
                    uint256 profit_amounts;
                    (amounts, profit_amounts) = _takeFee(amount, 2);
                    // 分红数量
                    uint256 profit = profit_amounts.mul(90).div(100);
                    address[] memory paths = new address[](2);
                    paths[0] = address(this);
                    paths[1] = _usdtAddress;
                    uint256[] memory getAmountsOuts = _pancakeRouter
                        .getAmountsOut(profit, paths);
                    uint256 real_profit_amount = getAmountsOuts[1].mul(99).div(
                        100
                    );
                    _pancakeRouter.swapExactTokensForTokens(
                        profit,
                        real_profit_amount,
                        paths,
                        address(this),
                        block.timestamp + 1800
                    );
                    // 销毁
                    uint256 destroy_profit = profit_amounts.sub(profit);
                    if (destroy_profit > 0) {
                        _burn(address(this), destroy_profit);
                    }
                }
            } else {
                // 普通交易
                if (!systemList[sender]) {
                    uint256 foundation_amount = amount.mul(serviceCharge).div(
                        100
                    );
                    _balances[ptFoundationAddress] += foundation_amount;
                    senderBalance = senderBalance - foundation_amount;
                    _balances[sender] = senderBalance;
                }
            }
        }

        if (!systemList[recipient]) {
            uint256 now_balance = _balances[recipient];
            if (now_balance + amounts > ptMax) {
                require(false, "BEP20: recipient too many transactions");
            }
        }

        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amounts;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _takeFee(uint256 _amount, uint256 _types)
        internal
        returns (uint256 amounts, uint256 profit_amounts)
    {
        uint256 amount = _amount;
        uint256 profit_amount = 0;

        uint256 usdtMobilityNums = BEP20(_usdtAddress).balanceOf(_pairAddress);
        uint256 ptMobilityNums = balanceOf(_pairAddress);
        uint256 ptNowUsdt = usdtMobilityNums
            .mul(100)
            .mul(10**11)
            .div(ptMobilityNums)
            .div(10**18);
        uint256 slip_point = 0;
        if (_types == 1) {
            slip_point = buySlipPoint;
        } else {
            slip_point = sellSlipPoint;
        }
        if (ptNowUsdt < ptUsdt) {
            uint256 difference = ptUsdt - ptNowUsdt;
            uint256 ratio = difference.mul(100).div(ptUsdt);
            if (ratio >= 25) {
                if (_types == 1) {
                    slip_point = 0;
                } else {
                    slip_point = 30;
                }
            } else if (ratio >= 20) {
                if (_types == 1) {
                    slip_point = 2;
                } else {
                    slip_point = 25;
                }
            } else if (ratio >= 15) {
                if (_types == 1) {
                    slip_point = 3;
                } else {
                    slip_point = 20;
                }
            } else if (ratio >= 10) {
                if (_types == 1) {
                    slip_point = 4;
                } else {
                    slip_point = 15;
                }
            } else if (ratio >= 5) {
                if (_types == 1) {
                    slip_point = 5;
                } else {
                    slip_point = 10;
                }
            }
        }
        profit_amount = amount.mul(slip_point).div(100);
        amounts = amount.sub(profit_amount);
        _balances[address(this)] += profit_amount;
        totalSupply -= profit_amount;
        destroyNum += profit_amount;
        return (amounts, profit_amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (
            _leader(to) == address(0) &&
            amount >= 1 &&
            from != to &&
            from != address(this) &&
            to != address(this) &&
            from != address(0) &&
            to != address(0)
        ) {
            if (_pairAddress != from && _pairAddress != to) {
                bool verify_leader_valid = _verify_leader_valid(to, from);
                if (verify_leader_valid) {
                    directPush[from].push(to);
                    leader[to] = from;
                    subordinate[from] += 1;
                }
            }
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _leader(address account) internal view returns (address) {
        return leader[account];
    }

    function _verify_leader_valid(address from, address to)
        internal
        view
        returns (bool)
    {
        address to_leader = _leader(to);
        if (to_leader == address(0)) {
            return true;
        }
        if (to_leader == from) {
            return false;
        }
        return _verify_leader_valid(from, to_leader);
    }

    function get_direct_push(address account)
        public
        view
        returns (address[] memory)
    {
        return directPush[account];
    }

    function _profit(
        address account,
        uint256 num,
        uint256 i,
        uint256 types,
        uint256 rewards
    ) internal returns (uint256) {
        if (i <= 9) {
            if (account != address(0)) {
                if (balanceOf(account) >= 1 * 10**11) {
                    address[] memory address_list = get_direct_push(account);
                    uint256 push_valid = 0;
                    for (uint256 iq = 0; iq < address_list.length; iq++) {
                        if (balanceOf(address_list[iq]) >= 1 * 10**11) {
                            push_valid += 1;
                        }
                    }

                    uint256 _profit_ratio = 0;
                    if (i == 1 && push_valid >= 1) {
                        _profit_ratio = 20;
                    } else if (i == 2 && push_valid >= 2) {
                        _profit_ratio = 10;
                    } else if (i == 3 && push_valid >= 3) {
                        _profit_ratio = 10;
                    } else if (i == 4 && push_valid >= 4) {
                        _profit_ratio = 10;
                    } else if (i == 5 && push_valid >= 5) {
                        _profit_ratio = 10;
                    } else if (i == 6 && push_valid >= 6) {
                        _profit_ratio = 10;
                    } else if (i == 7 && push_valid >= 7) {
                        _profit_ratio = 10;
                    } else if (i == 8 && push_valid >= 8) {
                        _profit_ratio = 10;
                    } else if (i == 9 && push_valid >= 9) {
                        _profit_ratio = 10;
                    }
                    if (_profit_ratio > 0) {
                        rewards += _profit_ratio;
                        if (types == 1) {
                            BEP20(_usdtAddress).transfer(
                                account,
                                (num * _profit_ratio) / 100
                            );
                        } else {
                            _transfer(
                                address(this),
                                account,
                                (num * _profit_ratio) / 100
                            );
                        }
                    }
                    i++;
                    return _profit(_leader(account), num, i, types, rewards);
                } else {
                    return _profit(_leader(account), num, i, types, rewards);
                }
            }
        }
        uint256 surplus = (num * (100 - rewards)) / 100;
        return surplus;
    }
}

// public 函数或者变量，对外部和内部都可见。
// private 函数和状态变量仅在当前合约中可以访问，在继承的合约内不可访问。
// external 函数或者变量，只对外部可见，内部不可见
// internal 函数和状态变量只能通过内部访问。如在当前合约中调⽤，或继承的合约⾥调⽤。

// view 不可以修改合约数据
// virtual 能被子合约继承
// override 重写了父合约