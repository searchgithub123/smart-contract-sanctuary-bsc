/**
 *Submitted for verification at BscScan.com on 2022-10-05
*/

/**
 *Submitted for verification at BscScan.com on 2022-09-09
*/

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "e3");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ow1");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ow2");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "e4");
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}

interface IERC721Enumerable {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintForMiner(address _to) external returns (bool, uint256);

    function MinerList(address _address) external returns (bool);
}

interface structItem {
    struct nftInfo {
        string name;
        string symbol;
        string tokenURI;
        address ownerOf;
        tokenIdInfo statusList;
    }

    struct tokenIdInfo {
        bool mintStatus;
        bool buybackStatus;
        bool swapStatus;
    }

}

interface p {
    struct allStakingItem {
        address pool;
        uint256 stakingNum;
        uint256[] stakingList;
    }
}

interface IgoManager is p {
    function getAllStakingNum(address _user) external view returns (uint256 num);

    function massGetStaking(address _user) external view returns (allStakingItem[] memory allStakingList, uint256[] memory tokenIdList);
}

// interface dao {
//     function stakingNftOlderOwnerList(address _nftToken, uint256 _tokenID) external view returns (address);
// }


interface rewardOsPlus {
    function refererAddressList(address _user) external view returns (address);

    function addRewardList(address _user, uint256 _rewardAmount, uint256 _type) external;

    function refererRate() external view returns (uint256);

    function userRate() external view returns (uint256);
}

interface swapRouter {
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

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);


    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
}

interface MasterChefForErc20 {
    function depositProxyList(address _user) external returns (bool);

    function depositByProxy(address _user, uint256 _pid, uint256 _depositAmount) external;
}

contract IGOPoolV2 is Ownable, ReentrancyGuard, structItem, p {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    uint256 private quote;
    address payable public feeAddress;
    address payable public teamAddress;
    address public IGOPoolFactory;
    address public swapPool;
    //dao public daoAddress;
    //uint256 public daoRate;
    bool public useSwapPool = true;
    IgoManager public igoManager = IgoManager(0x6a774459E43da4B8771ab753828062f700ceBE50);
    mapping(address => mapping(uint256 => bool)) public CanBuyBackList;
    mapping(address => uint256[]) public UserIgoTokenIdList;
    mapping(address => uint256) public UserIgoTokenIdListNum;
    mapping(uint256 => tokenIdInfo) public TokenIdSwapStatusStatusList;
    uint256 public stakingIgoNum;
    uint256 public whiteListIgoNum;
    multi_item public quoteList;
    bool public useRewardOsPlus = false;
    rewardOsPlus public rewardOsPlusAddress;
    swapItem public swapConfig;
    uint256[] public additionalFeeList = [10,100];

    struct swapItem {
        //uint256 minWhiteAmount;
        swapRouter routerAddress; //swap bnb for usdt
        swapRouter routerAddress2; //swap usdt for cot
        IERC20 usdtToken;
        IERC20 pairAddress;
        address[] swapErc20Path;
        address[] swapEthPath;
        MasterChefForErc20 farmAddress;
        uint256 farmPid;
        uint256 rewardPid;
    }

    mapping(address => bool) public whiteList;
    mapping(address => uint256) public whiteQuoteList;

    struct multi_item {
        uint256 stakingTotal;
        uint256 whiteListTotal;
    }

    struct orderItem_1 {
        uint256 orderId;
        IERC721Enumerable nftToken;
        uint256 igoTotalAmount;
        address erc20Token;
        uint256 price;
        bool orderStatus;
        uint256 igoOkAmount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 cosoQuote;
        bool useWhiteListCheck;
    }

    struct orderItem_2 {
        IERC20 swapToken;
        uint256 swapPrice;
        uint256 buyBackEndBlock;
        uint256 buyBackNum;
        uint256 swapFee;
        uint256 igoMaxAmount;
        IERC721Enumerable CosoNFT;
        bool useStakingCoso;
        bool useWhiteList;
        IERC20 ETH;
    }

    orderItem_1 public fk1;
    orderItem_2 public fk2;


    function setAdditionalFeeList(uint256[] memory _additionalFeeList) external onlyOwner {
        require(_additionalFeeList.length == 2,"e001");
        require(_additionalFeeList[1]>=_additionalFeeList[0],"e002");
        additionalFeeList = _additionalFeeList;
    }

    constructor(IERC721Enumerable _Coso, address _feeAddress, address _teamAddress, IERC20 _ETH, uint256 orderId, IERC721Enumerable _nftToken, uint256 _igoAmount, address _erc20Token, uint256 _price, uint256 _swapRate) public {
        IGOPoolFactory = msg.sender;
        feeAddress = payable(_feeAddress);
        teamAddress = payable(_teamAddress);
        fk2.CosoNFT = _Coso;
        fk2.ETH = _ETH;
        fk1.cosoQuote = 1;
        fk1.orderId = orderId;
        fk1.orderStatus = true;
        fk1.nftToken = _nftToken;
        fk1.igoTotalAmount = _igoAmount;
        fk1.erc20Token = _erc20Token;
        fk1.price = _price;
        fk1.igoOkAmount = 0;
        fk2.swapFee = _swapRate;
        fk2.igoMaxAmount = 0;
        quote = _igoAmount;
    }

    modifier onlyIGOPoolFactory() {
        require(msg.sender == IGOPoolFactory, "e00");
        _;
    }

    modifier onlyBeforeStartBlock() {
        require(block.timestamp < fk1.startBlock || fk1.startBlock == 0, "e01");
        _;
    }

    function setIgoManager(IgoManager _igoManager) external onlyOwner {
        igoManager = _igoManager;
    }

    function setRewardOsPlus(bool _useRewardOsPlus, rewardOsPlus _rewardOsPlusAddress) external onlyOwner {
        useRewardOsPlus = _useRewardOsPlus;
        rewardOsPlusAddress = _rewardOsPlusAddress;
    }


    function setSwapConfig(swapRouter _routerAddress, swapRouter _routerAddress2, IERC20 _usdtToken, IERC20 _pairAddress, address[] calldata _swapErc20Path, address[] calldata _swapEthPath, MasterChefForErc20 _farmAddress, uint256 _farmPid, uint256 _rewardPid) external onlyOwner {
        swapConfig = swapItem(_routerAddress, _routerAddress2, _usdtToken, _pairAddress, _swapErc20Path, _swapEthPath, _farmAddress, _farmPid, _rewardPid);
    }


    function addWhiteQuoteList(address[] memory _addressList, uint256[] memory _quoteList) external onlyOwner {
        require(_addressList.length == _quoteList.length || _quoteList.length == 1, "e1");
        for (uint256 i = 0; i < _addressList.length; i++) {
            require(_addressList[i] != address(0), "e02");
            whiteList[_addressList[i]] = true;
            if (_quoteList.length == 1) {
                whiteQuoteList[_addressList[i]] = _quoteList[0];
            } else {
                whiteQuoteList[_addressList[i]] = _quoteList[i];
            }
        }
    }

    function setQuoteList(uint256 _stakingTotal, uint256 _whiteListTotal) external onlyOwner {
        quoteList.stakingTotal = _stakingTotal;
        quoteList.whiteListTotal = _whiteListTotal;
    }

    function enableIgo() external onlyOwner {
        fk1.orderStatus = true;
    }

    function disableIgo() external onlyOwner {
        fk1.orderStatus = false;
    }

    function setIgo(address payable _feeAddress, uint256 _fee, IERC721Enumerable _CosoNft, IERC721Enumerable _nftToken) external onlyIGOPoolFactory {
        feeAddress = _feeAddress;
        fk2.swapFee = _fee;
        fk2.CosoNFT = _CosoNft;
        fk1.nftToken = _nftToken;
    }

    function setOrderId(uint256 _orderId) external onlyOwner {
        fk1.orderId = _orderId;
    }

    function setTeamAddress(address payable _teamAddress) external onlyOwner {
        require(_teamAddress != address(0), "e01");
        teamAddress = _teamAddress;
    }

    function setIgoTotalAmount(uint256 _igoTotalAmount) external onlyOwner {
        fk1.igoTotalAmount = _igoTotalAmount;
    }

    function setErc20token(address _token, uint256 _price) external onlyOwner {
        fk1.erc20Token = _token;
        fk1.price = _price;
    }

    function updateBuybackFee(uint256 _swapFee) external onlyOwner {
        fk2.swapFee = _swapFee;
    }

    function setNftToken(IERC721Enumerable _nftToken) external onlyOwner {
        fk1.nftToken = _nftToken;
    }

    function setQuote(uint256 _quote) external onlyOwner {
        quote = _quote;
    }

    function setTaskType(uint256 _igoMaxAmount, bool _useWhiteList, bool _useWhiteListCheck, bool _useStakingCoso, uint256 _CosoQuote, bool _useSwapPool) external onlyOwner {
        fk2.igoMaxAmount = _igoMaxAmount;
        fk1.useWhiteListCheck = _useWhiteListCheck;
        fk2.useWhiteList = _useWhiteList;
        fk2.useStakingCoso = _useStakingCoso;
        fk1.cosoQuote = _CosoQuote;
        useSwapPool = _useSwapPool;
    }

    function setSwapPool(address _swapPool) external onlyOwner {
        require(_swapPool != address(0));
        swapPool = _swapPool;
    }

    function setSwapTokenPrice(IERC20 _swapToken, uint256 _swapPrice) external onlyOwner {
        require(block.timestamp <= fk1.endBlock || address(fk2.swapToken) == address(0), "e06");
        fk2.swapToken = _swapToken;
        fk2.swapPrice = _swapPrice;
    }

    function setTimeLines(uint256 _startBlock, uint256 _endBlock, uint256 _buyBackEndBlock) external onlyOwner {
        require(_buyBackEndBlock > _endBlock && _endBlock > _startBlock, "e07");
        fk1.startBlock = _startBlock;
        fk1.endBlock = _endBlock;
        fk2.buyBackEndBlock = _buyBackEndBlock;
    }

    function getStakingNum(address _user) external view returns (uint256 stakingNum, uint256 igoMaxAmount) {
        stakingNum = igoManager.getAllStakingNum(_user);
        igoMaxAmount = fk2.igoMaxAmount;
    }

    function getStaking(address _user) external view returns (uint256[] memory idTokenList, uint256 idTokenListNum, nftInfo[] memory nftInfolist2, uint256 igoQuota, uint256 maxIgoNum) {
        (, idTokenList) = igoManager.massGetStaking(_user);
        idTokenListNum = idTokenList.length;
        nftInfolist2 = massGetNftInfo(fk2.CosoNFT, idTokenList);
        igoQuota = (idTokenList.length).sub(UserIgoTokenIdListNum[_user]);
        maxIgoNum = fk2.igoMaxAmount;
    }

    // function getInWhiteList() payable external {
    //     require(swapConfig.farmAddress.depositProxyList(address(this)), "e001");
    //     require(!whiteList[msg.sender], "e002");
    //     uint256 _allAmount = fk1.price.div(10);
    //     if (fk1.erc20Token != address(0)) {
    //         require(msg.value == 0, "e001");
    //         IERC20(swapConfig.swapErc20Path[0]).safeTransferFrom(msg.sender, address(this), _allAmount);
    //     } else {
    //         (uint256[] memory amounts) = swapConfig.routerAddress.swapExactETHForTokens{value : _allAmount}(
    //             0,
    //             swapConfig.swapEthPath,
    //             address(this),
    //             block.timestamp
    //         );
    //         _allAmount = amounts[1];
    //     }
    //     uint256 halfAmount = _allAmount.mul(50).div(100);
    //     (uint256[] memory amounts) = swapConfig.routerAddress2.swapExactTokensForTokens(halfAmount, 0, swapConfig.swapErc20Path, address(this), block.timestamp);
    //     (,,uint256 lpAmount) = swapConfig.routerAddress2.addLiquidity(address(swapConfig.swapErc20Path[1]), address(swapConfig.swapErc20Path[0]), amounts[1], halfAmount, 0, 0, address(this), block.timestamp);
    //     swapConfig.farmAddress.depositByProxy(msg.sender, swapConfig.farmPid, lpAmount);
    //     whiteList[msg.sender] = true;
    //     whiteQuoteList[msg.sender] = 1;
    // }

    function setApprovedForSwapAndFarm(uint256 _amount) external onlyOwner {
        require(address(swapConfig.routerAddress) != address(0));
        require(address(swapConfig.routerAddress2) != address(0));
        require(address(swapConfig.swapErc20Path[0]) != address(0));
        require(address(swapConfig.swapErc20Path[1]) != address(0));
        require(address(swapConfig.pairAddress) != address(0));
        require(address(swapConfig.farmAddress) != address(0));
        IERC20(swapConfig.swapErc20Path[0]).approve(address(swapConfig.routerAddress2), _amount);
        IERC20(swapConfig.swapErc20Path[1]).approve(address(swapConfig.routerAddress2), _amount);
        swapConfig.pairAddress.approve(address(swapConfig.farmAddress), _amount);
    }

    event igoEvent(address _buyer, uint256 _idoNum, uint256[] _idoIdList, uint256 _amount, uint256 _time, uint256 _cosoID);

    function igo(uint256 idoNum, uint256 _cosoID) external payable nonReentrant {
        require(idoNum > 0, "e13");
        require(fk1.nftToken.MinerList(address(this)), "e14");
        require(fk1.orderStatus, "e15");
        require(block.timestamp >= fk1.startBlock && block.timestamp <= fk1.endBlock, "e16");
        require(fk1.igoOkAmount.add(idoNum) <= fk1.igoTotalAmount || fk1.igoOkAmount.add(idoNum) <= quote, "e17");
        uint256 cocoID = _cosoID;
        require(UserIgoTokenIdListNum[msg.sender].add(idoNum) <= fk2.igoMaxAmount, "e18");
        bool takeTX = true;
        if (fk2.useWhiteList && fk1.useWhiteListCheck && fk2.useStakingCoso && whiteList[msg.sender]) {
            cocoID = 0;
            require(UserIgoTokenIdListNum[msg.sender].add(idoNum) <= whiteQuoteList[msg.sender]);
            require(whiteListIgoNum.add(idoNum) <= quoteList.whiteListTotal);
            whiteListIgoNum = whiteListIgoNum.add(idoNum);
            takeTX = false;
        }
        if (fk2.useWhiteList && fk1.useWhiteListCheck && fk2.useStakingCoso && !whiteList[msg.sender]) {
            cocoID = 0;
            require(UserIgoTokenIdListNum[msg.sender].add(idoNum) <= igoManager.getAllStakingNum(msg.sender));
            require(stakingIgoNum.add(idoNum) <= quoteList.stakingTotal);
            stakingIgoNum = stakingIgoNum.add(idoNum);
        }
        if (fk2.useWhiteList && fk1.useWhiteListCheck && !fk2.useStakingCoso) {
            cocoID = 0;
            require(whiteList[msg.sender], "e20");
        }
        address referer = rewardOsPlusAddress.refererAddressList(msg.sender);
        uint256 allAmount = (fk1.price).mul(idoNum);
        uint256 additionalAmount = (fk1.price).mul(idoNum).mul(additionalFeeList[0]).div(additionalFeeList[1]);
        uint256 fee = allAmount.mul(fk2.swapFee).div(100);
        uint256 toTeam = allAmount.sub(fee);
        uint256 daoReward = fee.div(2);
        uint256 devAmount = fee.sub(daoReward);
        if (takeTX) {
            if (fk1.erc20Token == address(0))
            {
                require(msg.value == allAmount, "e21");
                teamAddress.transfer(toTeam);
            } else {
                require(IERC20(fk1.erc20Token).balanceOf(msg.sender) >= allAmount, "e22");
                IERC20(fk1.erc20Token).safeTransferFrom(msg.sender, teamAddress, toTeam);
                IERC20(fk1.erc20Token).safeTransferFrom(msg.sender, address(this), additionalAmount);
                //burn cot
                swapConfig.routerAddress2.swapExactTokensForTokens(additionalAmount, 0, swapConfig.swapErc20Path, address(1), block.timestamp);
            }
            if (fee > 0 && !useRewardOsPlus) {
                if (fk1.erc20Token == address(0)) {
                    feeAddress.transfer(fee);
                } else {
                    IERC20(fk1.erc20Token).safeTransferFrom(msg.sender, feeAddress, fee);
                }
            }
            if (fee > 0 && useRewardOsPlus) {
                if (fk1.erc20Token == address(0)) {
                    feeAddress.transfer(devAmount);
                    (uint256[] memory amounts) = swapConfig.routerAddress.swapExactETHForTokens{value : daoReward}(
                        0,
                        swapConfig.swapEthPath,
                        address(this),
                        block.timestamp
                    );
                    daoReward = amounts[1];
                } else {
                    IERC20(fk1.erc20Token).safeTransferFrom(msg.sender, feeAddress, devAmount);
                    IERC20(fk1.erc20Token).safeTransferFrom(msg.sender, address(this), daoReward);
                }
                (uint256[] memory amounts2) = swapConfig.routerAddress2.swapExactTokensForTokens(daoReward, 0, swapConfig.swapErc20Path, address(this), block.timestamp);
                daoReward = amounts2[1];
                IERC20 rewardToken = IERC20(swapConfig.swapErc20Path[1]);
                if (referer != address(0)) {
                    uint256 rewardAmountForReferer = daoReward.mul(rewardOsPlusAddress.refererRate()).div(100);
                    uint256 rewardAmountForUser = daoReward.sub(rewardAmountForReferer);
                    rewardToken.safeTransfer(referer, rewardAmountForReferer);
                    rewardToken.safeTransfer(msg.sender, rewardAmountForUser);
                    rewardOsPlusAddress.addRewardList(msg.sender, daoReward, swapConfig.rewardPid);
                } else {
                    rewardToken.safeTransfer(address(1), daoReward);
                }
            }
        }
        uint256[] memory idoIdList = new uint256[](idoNum);
        for (uint256 i = 0; i < idoNum; i++) {
            (bool mintStatus,uint256 _token_id) = fk1.nftToken.mintForMiner(msg.sender);
            require(mintStatus && _token_id > 0, "e23");
            TokenIdSwapStatusStatusList[_token_id].mintStatus = true;
            CanBuyBackList[msg.sender][_token_id] = true;
            UserIgoTokenIdList[msg.sender].push(_token_id);
            fk1.igoOkAmount = fk1.igoOkAmount.add(1);
            UserIgoTokenIdListNum[msg.sender] = UserIgoTokenIdListNum[msg.sender].add(1);
            idoIdList[i] = _token_id;
        }
        emit igoEvent(msg.sender, idoNum, idoIdList, allAmount, block.timestamp, cocoID);
    }

    function buyback(uint256[] memory _tokenIdList) external nonReentrant {
        require(block.timestamp > fk1.endBlock && block.timestamp < fk2.buyBackEndBlock, "e26");
        uint256 buybackNum = _tokenIdList.length;
        uint256 leftrate = uint256(100).sub(fk2.swapFee);
        uint256 allAmount = (fk1.price).mul(leftrate).mul(buybackNum).div(100);
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            require(CanBuyBackList[msg.sender][_tokenIdList[i]], "e27");
        }
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            fk1.nftToken.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _tokenIdList[i]);
            CanBuyBackList[msg.sender][_tokenIdList[i]] = false;
            fk2.buyBackNum = fk2.buyBackNum.add(1);
            TokenIdSwapStatusStatusList[_tokenIdList[i]].buybackStatus = true;
        }
        if (fk1.erc20Token != address(0)) {
            IERC20(fk1.erc20Token).safeTransfer(msg.sender, allAmount);
        } else {
            msg.sender.transfer(allAmount);
        }
    }

    function takeTokens(address _token) external onlyOwner returns (bool){
        if (_token == address(0)) {
            msg.sender.transfer(address(this).balance);
            return true;
        } else {
            IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
            return true;
        }
    }

    function getTimeStatus(uint256 _time) external view returns (bool canStaking, bool canIgo, bool canBuyBack, bool canWithDraw, bool canSwapToken) {
        if (_time < fk1.startBlock) {
            return (true, false, false, false, false);
        } else if (fk1.startBlock <= _time && _time <= fk1.endBlock) {
            return (false, true, false, false, true);
        } else if (fk1.endBlock < _time && _time <= fk2.buyBackEndBlock) {
            return (false, false, true, true, true);
        } else if (_time > fk2.buyBackEndBlock) {
            return (false, false, false, true, true);
        }
    }

    function getTokenInfoByIndex() external view returns (orderItem_1 memory orderItem1, orderItem_2 memory orderItem2, string memory name2, string memory symbol2, uint256 decimals2, uint256 price2, string memory nftName, string memory nftSymbol){
        orderItem1 = fk1;
        orderItem2 = fk2;
        if (orderItem1.erc20Token == address(0)) {
            name2 = fk2.ETH.name();
            symbol2 = fk2.ETH.symbol();
            decimals2 = fk2.ETH.decimals();
        } else {
            name2 = IERC20(orderItem1.erc20Token).name();
            symbol2 = IERC20(orderItem1.erc20Token).symbol();
            decimals2 = IERC20(orderItem1.erc20Token).decimals();
        }
        price2 = orderItem1.price.mul(1e18).div(10 ** decimals2);
        nftName = orderItem1.nftToken.name();
        nftSymbol = orderItem1.nftToken.symbol();
    }

    function getUserIdoTokenIdList(address _address) external view returns (uint256[] memory) {
        return UserIgoTokenIdList[_address];
    }

    function getNftInfo(IERC721Enumerable _nftToken, uint256 _tokenId) public view returns (nftInfo memory nftInfo2) {
        nftInfo2 = nftInfo(_nftToken.name(), _nftToken.symbol(), _nftToken.tokenURI(_tokenId), _nftToken.ownerOf(_tokenId), TokenIdSwapStatusStatusList[_tokenId]);
    }

    function massGetNftInfo(IERC721Enumerable _nftToken, uint256[] memory _tokenIdList) public view returns (nftInfo[] memory nftInfolist2) {
        nftInfolist2 = new nftInfo[](_tokenIdList.length);
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            nftInfolist2[i] = getNftInfo(_nftToken, _tokenIdList[i]);
        }
    }

    receive() payable external {}
}