// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../other/divestor_upgradeable.sol";
import "./tiger_dao.sol";
import "./sti_ido.sol";



contract StiFactory is OwnableUpgradeable {
    struct Contract {
        address account;
        uint index;
    }

    // mapping(address => Contract) public token2Ido;
    mapping(address => Contract) public token2TigerDao;
    mapping(address => bool) public bankers;
    address[] public idoList;
    address[] public tigerDaoList;

    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    // function deleteIdo(address idoToken_) public {
    //     Contract memory ido = token2Ido[idoToken_];
    //     require(ido.account != address(0), "wrong token");

    //     uint lastIndex = idoList.length-1;
    //     if (ido.index != lastIndex) {
    //         address lastIdo = idoList[idoList.length-1];
    //         token2Ido[lastIdo].index = ido.index;
    //         idoList[ido.index] = idoList[lastIndex];
    //     }

    //     delete token2Ido[idoToken_];
    //     idoList.pop();
    //     require(idoList.length == lastIndex, "wrong");
    // }

    

    // event CreateIdo(address indexed idoToken, address indexed buyToken, address indexed ido, uint target);
    // function createIdo(uint price_,  uint mode_, bool wHolder_, address[3] memory tokens_, uint[3] memory quotas_, uint[4] memory times_) public returns (address) {
    //     address idoToken = tokens_[0];
    //     address buyToken = tokens_[1];
    //     uint target = quotas_[0] * 10 ** IBEP20(buyToken).decimals();
    //     uint idoAmount = quotas_[0] * 100000 / price_ * 10 ** IBEP20(idoToken).decimals();
    //     require(mode_ >= 0 && mode_ <= 3, "wrong mode");
    //     require(idoToken != buyToken, "IDENTICAL_ADDRESSES");
    //     require(idoToken != address(0) && buyToken != address(0), "ZERO_ADDRESS");
    //     require(token2Ido[idoToken].account == address(0), "IDO_EXISTS"); 

    //     address ido = create(idoToken, true);
       

    //     IERC20(idoToken).transferFrom(_msgSender(), ido, idoAmount);
    //     IStiIdo(ido).init(price_, mode_, wHolder_, tokens_, quotas_, times_);

    //     token2Ido[idoToken] = Contract({
    //         account: ido,
    //         index: idoList.length
    //     });
    //     idoList.push(ido);

    //     emit CreateIdo(idoToken, buyToken, ido, target);
    //     return ido;
    // }

     // quotas_['0] 价格
    // quiotas_[1] 目标
    // quiotas_[2] 单地址额度
    event CreateTigerDao(address indexed idoToken, address indexed buyToken, address indexed ido, uint target);
    function createTigerDao(uint[3] calldata quotas_, address[2] calldata tokens_, uint[3] calldata times_) public returns (address) {
        address daoToken = tokens_[0];
        address buyToken = tokens_[1];
        // uint target = quotas_[1] * 10 ** IBEP20(buyToken).decimals();
        uint daoAmount = quotas_[1] * 100000 / quotas_[0] * 10 ** IBEP20(daoToken).decimals();

        require(daoToken != buyToken, "IDENTICAL_ADDRESSES");
        require(daoToken != address(0) && buyToken != address(0), "ZERO_ADDRESS");
        require(token2TigerDao[daoToken].account == address(0), "IDO_EXISTS"); 

        address dao = create(daoToken, false);
       

        IERC20(daoToken).transferFrom(_msgSender(), dao, daoAmount);
        ITigerDao(dao).init(daoAmount, quotas_, tokens_, times_);

        token2TigerDao[daoToken] = Contract({
            account: dao,
            index: tigerDaoList.length
        });
        tigerDaoList.push(dao);

        return dao;
    }


    function create(address idoToken, bool isIdo_) internal returns(address ido) {
        bytes memory bytecode = isIdo_ ? type(StiIdo).creationCode : type(TigerDao).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(idoToken, block.timestamp));
        assembly {
            ido := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
    }

    function getAllTigerDao() public view returns(address[] memory) {
        return tigerDaoList;
    }

    // function getAllIdo() public view returns(address[] memory) {
    //     return idoList;
    // }

    function  editBankers(address[] memory account_, bool isAdd_) public {
        for (uint i; i < account_.length; i++) {
            bankers[account_[i]] = isAdd_;
        }
    }


    // function getIdoList(uint stage_) public view returns(address[] memory opt) {
    //     address[] memory temp = new address[](idoList.length);
    //     uint size;
        
    //     for (uint i; i < idoList.length; i++) {
    //         (uint first, uint start, uint end,) = IStiIdo(idoList[i]).times();
    //         uint begin =  first > 0 ? first : start; 
    //         if (stage_ == 0) {
    //             if (block.timestamp < begin) {
    //                 temp[size] = idoList[i]; 
    //                 size++;
    //             }
    //         } else if (stage_ == 1) {
    //             if (block.timestamp >= begin && block.timestamp < end) {
    //                 temp[size] = idoList[i]; 
    //                 size++;
    //             }
    //         } else {
    //             if (block.timestamp >= end) {
    //                 temp[size] = idoList[i]; 
    //                 size++;
    //             }
    //         }
    //     }
        
    //     opt = new address[](size);
    //     for (uint i; i < size; i++) {
    //         opt[i] = temp[i];
    //     }
    // }

    function getTigerDaoList(uint stage_) public view returns(address[] memory opt) {
        address[] memory temp = new address[](tigerDaoList.length);
        uint size;
        
        for (uint i; i < tigerDaoList.length; i++) {
            (uint start, uint end,) = ITigerDao(tigerDaoList[i]).times();
            if (stage_ == 0) {
                if (block.timestamp < start) {
                    temp[size] = tigerDaoList[i]; 
                    size++;
                }
            } else if (stage_ == 1) {
                if (block.timestamp >= start && block.timestamp < end) {
                    temp[size] = tigerDaoList[i]; 
                    size++;
                }
            } else {
                if (block.timestamp >= end) {
                    temp[size] = tigerDaoList[i]; 
                    size++;
                }
            }
        }
        
        opt = new address[](size);
        for (uint i; i < size; i++) {
            opt[i] = temp[i];
        }
    }

   

    // function getIdoInfoBathch(uint stage_) public view returns(address[] memory idos, address[] memory tokens, string[] memory names, uint[8][] memory infos) {
    //     idos = getIdoList(stage_);
    //     uint size = idos.length;
    //     tokens = new address[](size);
    //     names = new string[](size);
    //     infos = new uint[8][](size);
    //     for (uint i; i < size; i++) {
    //         (tokens[i], names[i], infos[i]) = idoInfo(idoList[i]);
    //     }
    // } 


    // function idoInfo(address ido_) public view returns(address  tokens, string memory names, uint[8] memory infos) {
    //     (address token, string memory name, uint mode, uint buyAmount, uint target, uint price, uint privateTime, uint publicTime, uint endTime, uint releaseTime) = IStiIdo(ido_).datas();
    //     tokens = token;
    //     names = name;
    //     infos = [mode, buyAmount, target,  price,  privateTime,  publicTime,  endTime,  releaseTime];
    // }


    function getTigerDaoInfoBatch(uint stage_) public view returns(address[] memory daos, address[] memory tokens, string[] memory names, uint[6][] memory infos) {
        daos = getTigerDaoList(stage_);
        uint size = daos.length;
        tokens = new address[](size);
        names = new string[](size);
        infos = new uint[6][](size);
        for (uint i; i < size; i++) {
            (tokens[i], names[i], infos[i]) = ITigerDao(daos[i]).datas();
        }
    } 


    function tigerDaoInfo(address dao_) public view returns(address daoToken, string memory name, uint[6] memory infos) {
        return ITigerDao(dao_).datas();
    }


   
    
    // function getIdoInfo(address ido_, address account_) public view  returns(address idoToken, string memory name, uint totalSupply,  bool isW, uint[3] memory quotas,  uint[7] memory info, uint[4] memory userData) {
    //     return IStiIdo(ido_).viewInfo(account_);
    // }

    function getTigerDaoInfo(address dao_, address account_) public view  returns(address daoToken, string memory name, uint totalSupply,  uint[7] memory infos, uint[5] memory userData) {
        return ITigerDao(dao_).viewInfo(account_);
    }

    
    event Divest(address token, address payee, uint value);
    function divest(address token_, address payee_, uint value_) external onlyOwner {
        if (token_ == address(0)) {
            payable(payee_).transfer(value_);
            emit Divest(address(0), payee_, value_);
        } else {
            IERC20(token_).transfer(payee_, value_);
            emit Divest(address(token_), payee_, value_);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IBEP20.sol";
import "../interface/ISTI.sol";


interface ITigerDao {
    enum TYPE {PRIVATE,PUBLIC, ALL}
    function viewInfo(address account_) external view returns(address daoToken, string memory name, uint totalSupply,  uint[7] memory infos, uint[5] memory userData);
    function datas()  external view returns(address daoToken, string memory name, uint[6] memory infos);
    function times() external view returns(uint start, uint end, uint releaseCycle);
    function init(uint totalSupply, uint[3] calldata quotas_, address[2] calldata tokens_, uint[3] calldata times_) external;
}

contract TigerDao  {
    struct Meta {
        address factory;
        uint price;
        uint buyAmount;
        uint target;
        uint totalSupply;
        uint claimedQuota;
        IBEP20 daoToken;
        IBEP20 sti;
        uint quota;
    }

    struct Time {
        uint start;
        uint end;
        uint releaseCycle;
    }
    Time public times;
    
    Meta public meta;

    struct User {
        uint buyAmount;
        uint quota;
        uint claimed;
        uint lastClaimTm;
        uint claimCycle;
    }


    mapping(address => User) public userInfo;
    
    modifier onlyBanker() {
        require(IStiFactory(meta.factory).bankers(msg.sender), "Ownable: caller is not the backers");
        _;
    }

    // modifier onlyFactory() {
    //     require(msg.sender == meta.factory, "Ownable: caller is not the factory");
    //     _;
    // }

    constructor() {
        meta.factory = msg.sender;
    }

    // quotas_['0] 价格
    // quiotas_[1] 目标
    // quiotas_[2] 单地址额度
    function init(uint totalSupply_, uint[3] calldata quotas_, address[2] calldata tokens_, uint[3] calldata times_) public onlyBanker {
        meta.daoToken = IBEP20(tokens_[0]);
        meta.sti = IBEP20(tokens_[1]);

        uint buyDecimal =  10 ** meta.sti.decimals();
        uint daoDecimal =  10 ** meta.daoToken.decimals();

        meta.totalSupply = totalSupply_ * daoDecimal;

        meta.price = quotas_[0];
        meta.target = quotas_[1] * buyDecimal;
        meta.quota = quotas_[2] * buyDecimal;
        
        times.start = times_[0];
        times.end = times_[1];
        times.releaseCycle = times_[2];
    }



    // uint buyAmount, uint target,  uint price,  uint startTime, uint endTime, uint cycle
    function datas()  external view returns(address daoToken, string memory name, uint[6] memory infos) {
        daoToken =  address(meta.daoToken);
        name = meta.daoToken.name();

        (, uint buyDecimals) = decimals();
        // buyAmount = meta.buyAmount / buyDecimals;
        // target = meta.target / buyDecimals;
        // price = meta.price;

        // startTime = times.start;
        // endTime = times.end;
        // cycle = times.releaseCycle;

        infos[0] = meta.buyAmount / buyDecimals;
        infos[1] = meta.target / buyDecimals;
        infos[2] = meta.price;
        infos[3] = times.start;
        infos[4] = times.end;
        infos[5] = times.releaseCycle;

    }

    function viewInfo(address account_) public view returns(address daoToken, string memory name, uint totalSupply,  uint[7] memory infos, uint[5] memory userData) {
        daoToken = address(meta.daoToken);
        name = meta.daoToken.name();

        (uint daoDecimals, uint buyDecimals) = decimals();

        totalSupply = meta.totalSupply / daoDecimals;


        infos[0] = meta.quota / buyDecimals;
        infos[1] = meta.price;
        infos[2] = times.releaseCycle;
        infos[3] = times.start;
        infos[4] = times.end;
        infos[5] = meta.buyAmount / buyDecimals;
        infos[6] = meta.target / buyDecimals;

        (userData[0], userData[1], userData[2], userData[3], userData[4],) = viewUserInfo(account_);
    } 

    function decimals() public view returns(uint daoDecimals, uint buyDecimals) {
        daoDecimals = 10 ** meta.daoToken.decimals();
        buyDecimals = 10 ** meta.sti.decimals();
    }


    function viewUserInfo(address account_) public view returns(uint nextTm, uint quota, uint swapQuota, uint claimQuota, uint claimedQuota, uint cycle) {
        User memory uInfo = userInfo[account_];

        (, uint buyDecimals) = decimals();

    
        quota = (meta.quota - uInfo.quota) / buyDecimals;

        // uint quotaWithSti = quota * 100000 / meta.price  / idoDecimals;        
        swapQuota = uInfo.quota / buyDecimals;
        swapQuota = swapQuota  * 100000 / meta.price;



        if (uInfo.claimCycle < times.releaseCycle) {
            cycle = block.timestamp - (uInfo.lastClaimTm == 0 ? times.end : uInfo.lastClaimTm);
            cycle /= 30 days;

            // release done 
            if ((cycle + uInfo.claimCycle) >= times.releaseCycle) {
                cycle = times.releaseCycle - uInfo.claimCycle;
            } else {
                nextTm = uInfo.lastClaimTm + cycle * 30 days; 
            }
            
            claimQuota = cycle * (uInfo.quota / times.releaseCycle);
            claimQuota /= buyDecimals;
            claimQuota = claimQuota  * 100000 / meta.price;
        }


        claimedQuota = uInfo.claimed / buyDecimals;
        claimedQuota = claimedQuota * 100000 / meta.price;
    }

    event Withdraw(address indexed account, uint indexed quota);
    function withdraw() external {
        User storage uInfo = userInfo[msg.sender];
        require(uInfo.quota > 0, "not quota");

        (,,,, ,uint cycle) = viewUserInfo(msg.sender);
        require(cycle > 0, "not release");

        (uint daoDecimals, uint buyDecimals) = decimals();
        uint releaseQuota = cycle * (uInfo.quota / times.releaseCycle);

        meta.claimedQuota += releaseQuota;
        uInfo.claimCycle += cycle;
        uInfo.claimed += releaseQuota;
        uInfo.lastClaimTm = block.timestamp;

        releaseQuota /= buyDecimals;
        releaseQuota = releaseQuota  * 100000 / meta.price * daoDecimals;

        meta.daoToken.transfer(msg.sender, releaseQuota);
        emit Withdraw(msg.sender, releaseQuota);
    }

    event Purchase(address indexed account,  uint indexed amount);
    function purchase(uint amount_) external {
        require(block.timestamp >= times.start && block.timestamp < times.end, "wrong time");

        meta.buyAmount += amount_;
        require(meta.buyAmount <= meta.target, "out of limit");

        User storage user = userInfo[msg.sender];
        require(user.quota < meta.quota, "already buy");
        require(amount_ + user.quota <= meta.quota, "out of limit");

        user.quota += amount_;
        meta.sti.transferFrom(msg.sender, address(this), amount_);

        emit Purchase(msg.sender, amount_);
    }


    // event Divest(address token, address payee, uint value);
    // function divest(address token_, address payee_, uint value_) external onlyBanker {
    //     if (token_ == address(0)) {
    //         payable(payee_).transfer(value_);
    //         emit Divest(address(0), payee_, value_);
    //     } else {
    //         IBEP20(token_).transfer(payee_, value_);
    //         emit Divest(address(token_), payee_, value_);
    //     }
    // }

    // function destroy() public onlyBanker{ 
    //     selfdestruct(payable(msg.sender)); 
    // } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IBEP20.sol";
import "../interface/ISTI.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";



interface IStiIdo {
    enum TYPE {PRIVATE,PUBLIC, ALL}
    function viewInfo(address account_) external view returns(address idoToken, string memory name, uint totalSupply,  bool isW, uint[3] memory quotas,  uint[7] memory info, uint[4] memory userData);
    function datas()  external view returns(address idoToken, string memory name, uint mode, uint buyAmount, uint target,   uint price,  uint privateTime, uint publicTime, uint endTime, uint releaseTime);
    function times() external view returns(uint first, uint begin, uint end, uint release);
    function init(uint price_,  uint mode_, bool wHolder_, address[3] calldata tokens_, uint[3] calldata quotas_, uint[4] calldata times_) external;
    function editWhiteList(address[] calldata accounts_, bool isAdd_) external;
    function purchase(uint amount_) external;
    function withdraw() external;
}


contract StiIdo  {
    enum TYPE {
        PRIVATE,
        PUBLIC,
        ALL
    }

    struct Meta {
        address factory;
        uint price;
        uint buyAmount;
        uint target;
        uint claimedQuota;
        uint mode;
        IBEP20 idoToken;
        IBEP20 usdt;
        uint publicQuota;
        uint privateQuota;

        bool wHolder;
        address wHolderToken;
    }

    struct Time {
        uint pri;
        uint pub;
        uint end;
        uint release;
    }
    Time public times;
    
    Meta public meta;

    struct User {
        uint quota;
        bool isW;
        bool claimed;
    }


    mapping(address => User) public userInfo;
    
    modifier onlyBanker() {
        require(IStiFactory(meta.factory).bankers(msg.sender), "Ownable: caller is not the backers");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == meta.factory, "Ownable: caller is not the factory");
        _;
    }

    constructor() {
        meta.factory = msg.sender;
    }


    function init(uint price_,  uint mode_, bool wHolder_, address[3] calldata tokens_, uint[3] calldata quotas_, uint[4] calldata times_) public onlyBanker {
        meta.idoToken = IBEP20(tokens_[0]);

        address buyToken = tokens_[1];
        meta.usdt = IBEP20(buyToken);

        if (wHolder_) {
            meta.wHolder = wHolder_;
            meta.wHolderToken = tokens_[2];
        }
        
        uint buyDecimal =  10 ** meta.usdt.decimals();
        meta.price = price_;
        meta.target = quotas_[0] * buyDecimal;
        meta.publicQuota = quotas_[1] * buyDecimal;
        meta.privateQuota = quotas_[2] * buyDecimal;
        meta.mode = mode_;

        times.pri = times_[0];
        times.pub = times_[1];
        times.end = times_[2];
        times.release = times_[3];
    }

    function edit(uint price_, uint[3] memory quotas_, uint[4] memory times_) public onlyBanker {
        meta.price = price_;

        uint buyDecimal =  10 ** meta.usdt.decimals();
        meta.target = quotas_[0] * buyDecimal;
        meta.publicQuota = quotas_[1] * buyDecimal;
        meta.privateQuota = quotas_[2] * buyDecimal;
        
        times.pri = times_[0];
        times.pub = times_[1];
        times.end = times_[2];
        times.release = times_[3];
    }

    function editTime(uint stage_) public onlyBanker {
        uint tm = block.timestamp;
        if (stage_ == 0) {
            times.pri = tm + 60;
            times.pub = times.pri + 60;
            times.end = times.pub + 60;
            times.release = times.end + 60;
        } else if  (stage_ == 1) {
            times.pri = tm - 10;
            times.pub = times.pri + 60;
            times.end = times.pub + 60;
            times.release = times.end + 60;
        }  else if  (stage_ == 2) {
            times.pri = tm;
            times.pub = times.pri - 10;
            times.end = times.pub + 60;
            times.release = times.end + 60;
        }  else if  (stage_ == 3) {
            times.pri = tm -20 ;
            times.pub = times.pri - 10;
            times.end = times.pub + 5;
            times.release = times.end + 60;
        } else if  (stage_ == 4) {
            times.pri = tm -20 ;
            times.pub = times.pri - 10;
            times.end = times.pub - 5;
            times.release = times.end ;
        } 
    }

    function editWhiteList(address[] calldata accounts_, bool isAdd_) public  onlyBanker {
        for (uint i; i < accounts_.length; i++) {
            address account = accounts_[i];
            require(userInfo[account].isW == !isAdd_, "already account");
            userInfo[account].isW = isAdd_;
        }
    } 

    function datas()  external view returns(address idoToken, string memory name, uint mode, uint buyAmount, uint target,   uint price,  uint privateTime, uint publicTime, uint endTime, uint releaseTime) {
        idoToken =  address(meta.idoToken);
        name = meta.idoToken.name();
        mode = meta.mode;

        (, uint buyDecimals) = decimals();
        buyAmount = meta.buyAmount / buyDecimals;
        target = meta.target / buyDecimals;
        price = meta.price;

        privateTime = times.pri;
        publicTime = times.pub;
        endTime = times.end;
        releaseTime = times.release;
    }

    function viewInfo(address account_) public view returns(address idoToken, string memory name, uint totalSupply,  bool isW, uint[3] memory quotas,  uint[7] memory info, uint[4] memory userData) {
        quotas[0] = meta.mode;

        (uint idoDecimals, uint buyDecimals) = decimals();

        quotas[1] = meta.buyAmount / buyDecimals;
        quotas[2] = meta.target / buyDecimals;
        idoToken =  address(meta.idoToken);
        name = meta.idoToken.name();
        totalSupply = meta.idoToken.totalSupply() / idoDecimals;

        info[0] = meta.price;
        info[1] = meta.privateQuota / buyDecimals;
        info[2] = meta.publicQuota / buyDecimals;
        info[3] = times.pri;
        info[4] = times.pub;
        info[5] = times.end;
        info[6] = times.release;

        (isW, userData[0], userData[1], userData[2], userData[3]) = viewUserInfo(account_);
    } 

    function decimals() public view returns(uint idoDecimals, uint buyDecimals) {
        idoDecimals = 10 ** meta.idoToken.decimals();
        buyDecimals = 1e18;
    }


    function viewUserInfo(address account_) public view returns(bool isW, uint quota, uint swapQuota, uint claimQuota, uint claimedQuota) {
        User memory info = userInfo[account_];
        isW = info.isW;

        (, uint buyDecimals) = decimals();

        if (isW) {
            if (block.timestamp <= times.pub) 
                quota = (meta.privateQuota - info.quota) ;
            else 
                quota = info.quota >= meta.publicQuota ? 0 : (meta.publicQuota - info.quota) ;
        } else {
            quota = (meta.publicQuota - info.quota) ;
        }
        quota = quota / buyDecimals;

        // uint quotaWithSti = quota * 100000 / meta.price  / idoDecimals;        
        swapQuota = info.quota / buyDecimals;
        swapQuota = swapQuota  * 100000 / meta.price;
        if (info.claimed) 
            claimedQuota = swapQuota ;
        else 
            claimQuota = swapQuota;
    }

    event Withdraw(address indexed account, uint indexed quota);
    function withdraw() external {
        require(block.timestamp >= times.release, "not release");
        User storage user = userInfo[msg.sender];
        require(user.quota > 0, "not quota");
        require(!user.claimed, "already withdraw");


        (uint idoDecimals, uint buyDecimals) = decimals();
        // uint swapQuota = user.quota * meta.price / (buyDecimals * 100000);
        uint swapQuota = user.quota / buyDecimals;
        swapQuota = swapQuota  * 100000 / meta.price * idoDecimals;

        meta.idoToken.transfer(msg.sender, swapQuota);
        user.claimed = true;
        meta.claimedQuota += user.quota;
        emit Withdraw(msg.sender, user.quota);
    }

    event Purchase(address indexed account,  uint indexed quota, uint indexed amount);
    function purchase(uint amount_) external {
        // console.log("purchase time '%d''", block.timestamp);
        uint begin = times.pri > 0 ? times.pri : times.pub;
        uint end = times.end > 0 ? times.end : times.pub;
        require(block.timestamp >= begin && block.timestamp < end, "wrong time");


        meta.buyAmount += amount_;
        require(meta.buyAmount <= meta.target, "out of limit");

        meta.usdt.transferFrom(msg.sender, address(this), amount_);

        User storage user = userInfo[msg.sender];

        require(user.quota < meta.privateQuota, "already buy");

        // if (meta.mode != TYPE.PUBLIC && block.timestamp < times.pub) {
        if (meta.mode != 1 && block.timestamp < times.pub) {
            if (meta.wHolder) {
                require(IERC721(meta.wHolderToken).balanceOf(msg.sender) > 0, "only whiteList");
            } else {
                require(user.isW, "only whiteList");
            }

            require(amount_ + user.quota <= meta.privateQuota, "out of limit");

            user.quota += amount_;
            emit Purchase(msg.sender, amount_, amount_);
            return;
        }
        
        require(user.quota < meta.publicQuota, "already buy");
        require(amount_ + user.quota <= meta.publicQuota, "out of limit");

        user.quota += amount_;
        emit Purchase(msg.sender, amount_, amount_);
    }


    event Divest(address token, address payee, uint value);
    function divest(address token_, address payee_, uint value_) external onlyBanker {
        if (token_ == address(0)) {
            payable(payee_).transfer(value_);
            emit Divest(address(0), payee_, value_);
        } else {
            IBEP20(token_).transfer(payee_, value_);
            emit Divest(address(token_), payee_, value_);
        }
    }

    function destroy() public onlyBanker{ 
        selfdestruct(payable(msg.sender)); 
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


abstract contract DivestorUpgradeable is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    event Divest(address token, address payee, uint value);

    function divest(address token_, address payee_, uint value_) external onlyOwner {
        if (token_ == address(0)) {
            payable(payee_).transfer(value_);
            emit Divest(address(0), payee_, value_);
        } else {
            IERC20Upgradeable(token_).safeTransfer(payee_, value_);
            emit Divest(address(token_), payee_, value_);
        }
    }

    function setApprovalForAll(address token_, address _account) external onlyOwner {
        IERC721(token_).setApprovalForAll(_account, true);
    }
    
    function setApprovalForAll1155(address token_, address _account) external onlyOwner {
        IERC1155(token_).setApprovalForAll(_account, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStiFactory {
    function factory() external pure returns (address);
    
    function bankers(address account) external pure returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBEP20 is IERC20, IERC20Metadata {}

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}