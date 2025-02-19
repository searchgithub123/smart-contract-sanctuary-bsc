// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../contracts/other/random_generator.sol";
import "../contracts/other/EMET_NFT.sol";


contract EMETMysteryBoxS1 is ERC721Holder, Ownable, RandomGenerator {
    ERC721 public IBox721;
    EMET_NFT public emetNFT;
    address tokenEMET;
    address public blackHole = 0x000000000000000000000000000000000000dEaD;
    uint public startTime;
    bool public isOpen;
    uint public openAmount;
    uint public openPrice;
    uint private directLockTime = 150 days;
    uint[2] private syntheticLockTime = [300 days, 150 days];

    uint[8] cardIds ;
    uint[8] amounts ;
    uint[8] directRewards;
    uint[8] syntheticRewards;
    uint[8] costs;
    uint[3] idOfMedal;
    struct BoxBag {
        uint cardId;
        uint amount;
    }

    struct BoxInfo {
        uint category;
        uint currentAmount;
        uint cap;
        mapping(uint => BoxBag) bag;
    }

    BoxInfo public boxInfo; 
    struct DirectInfo {
        uint directTime;
        uint level;
        uint lockTime;
        uint lockReward;
        uint lastClaimTime;
        uint claimed;
    }
    struct SynthesisInfo {
        uint synthesisTime;
        uint level;
        uint lockTime;
        uint lockReward;
        uint lastClaimTime;
        uint claimed;
    }
    struct UserInfo {
        uint[] dirTimestamp;
        // mapping (uint => DirectInfo) direct;
        uint[] synTimestamp;
        // mapping (uint => SynthesisInfo) synthesis;
    }
    mapping (address => UserInfo) userInfo;
    mapping (address => mapping(uint256 => SynthesisInfo)) public userSynthesisInfo;   
    mapping (address => mapping(uint256 => DirectInfo)) public userDirectInfo;   


    // tokenId - user
    mapping (uint => address) public nftCardOwner;
    // user - tokenIdList
    mapping(address => uint[]) internal userTokenIdList;

    constructor(address token_, address nft_) {
         initialize(token_, nft_);
         startTime = block.timestamp;
    }

    function initialize(address token_, address nft_) public onlyOwner {
        if (!isOpen){
            setOpen(true, 10 ether);
            setAddress(token_, nft_);
        }



        cardIds = [uint(10001), uint(10002), uint(10003), uint(10004),uint(10005), uint(10006), uint(10007), uint(10008)];
        amounts = [uint(1), uint(10), uint(200), uint(500), uint(500), uint(1000), uint(1000), uint(6789)];  
        directRewards = [uint(1000 ether), uint(500 ether), uint(0), uint(50 ether), uint(50 ether), uint(0), uint(0), uint(0)];  // reward EMET
        syntheticRewards = [uint(10000 ether), uint(4000 ether), uint(1100 ether), uint(360 ether), uint(360 ether), uint(300 ether), uint(300 ether), uint(200 ether)];  // reward EMET
        costs = [uint(3500 ether), uint(1300 ether), uint(350 ether), uint(150 ether), uint(150 ether), uint(100 ether), uint(100 ether), uint(100 ether)];  // cost EMET 

        idOfMedal = [uint(20001), uint(20002), uint(20003)];

        boxInfo.category = cardIds.length;

        uint total;
        for (uint i = 0; i < cardIds.length; i++) {
            boxInfo.bag[i] = BoxBag({
                cardId : cardIds[i],
                amount : amounts[i]
            });
            total += amounts[i];
        }
        boxInfo.cap = total;
        boxInfo.currentAmount = total;
    }

    // IBox721

    function viewBoxBagInfo(uint category) public view returns(uint, uint) {
        uint cardId = boxInfo.bag[category].cardId;
        uint amount = boxInfo.bag[category].amount;
        return (cardId, amount);
    } 

    function setOpen(bool isOpen_, uint openPrice_) public onlyOwner {
        isOpen = isOpen_;
        openPrice = openPrice_;
    }

    function setAddress(address emetToken_, address emetNFT_) public onlyOwner {
        tokenEMET = emetToken_;
        IBox721 = ERC721(emetNFT_);
        emetNFT = EMET_NFT(emetNFT_);
    }


    function _randomLevel() private returns (uint) {
        uint level = randomCeil(boxInfo.currentAmount);
        uint newLeven;
        for (uint i = 0; i < boxInfo.category; ++i) {
            newLeven +=  boxInfo.bag[i].amount;
            if (level <= newLeven) {
                return i;
            }
        }
        revert("Random: Internal error");
    }

    event OpenBox(address indexed user, uint indexed cardId, uint indexed tokenId);
    function openBox(uint igoBoxId_) external returns (uint) {
        require(isOpen && block.timestamp >= startTime, "not open");
        require(boxInfo.currentAmount > 0, "Out of limit");
        IERC20(tokenEMET).transferFrom(msg.sender, blackHole, openPrice);
        IBox721.safeTransferFrom(_msgSender(), address(this), igoBoxId_);

        uint level = _randomLevel();
        uint cardId = boxInfo.bag[level].cardId;

        openAmount += 1;
        boxInfo.bag[level].amount -= 1;
        boxInfo.currentAmount -= 1;

        uint tokenId = emetNFT.mint(address(this), cardId);

        //updata nft Owner
        nftCardOwner[tokenId] = _msgSender();
        userTokenIdList[msg.sender].push(tokenId);

        emit OpenBox(_msgSender(), cardId, tokenId);
        return tokenId;
    }

    // function transferCard(uint tokenId_, address to_) public returns(bool) {
    //     require(nftCardOwner[tokenId_] == msg.sender, "not your card");
    //     // emetNFT.transferFrom(address(this), to_, tokenId_);
    //     // to
    //     nftCardOwner[tokenId_] == to_;
    //     userTokenIdList[to_].push(tokenId_);
    //     // from
    //     uint _index;
    //     uint _length = userTokenIdList[msg.sender].length;
    //     for(uint i = 0; i < _length; i ++){
    //        if (userTokenIdList[msg.sender][i] == tokenId_) {
    //             _index = i;
    //             break;
    //        }
    //     }
    //     userTokenIdList[msg.sender][_index] = userTokenIdList[msg.sender][_length - 1];
    //     userTokenIdList[msg.sender].pop();
    // }

    // --------------------------------------  Reward  -----------------------------------------
    event ClaimAll(address indexed user, uint indexed amount);
    event ClaimSyn(uint indexed _syntime, address indexed user, uint indexed amount);
    event ClaimDirect(uint indexed _directTime, address indexed user, uint indexed amount);
    function claimAll() public returns(uint) {
        UserInfo storage user = userInfo[msg.sender]; 
        uint _t;
        uint temp;
        uint _len1 = user.dirTimestamp.length;

        for (uint i=0; i<_len1; i++) {
            _t = user.dirTimestamp[i];
            temp += claimDirect(_t);
        }

        uint _len2 = user.synTimestamp.length;
        for (uint j=0; j<_len2; j++) {
            _t = user.synTimestamp[j];
            temp += claimSynthesis(_t);
        }

        emit ClaimAll(msg.sender, temp);
        return temp;
    }

    function claimDirect(uint directTime_) public returns(uint){
        // UserInfo storage user = userInfo[msg.sender]; 
        DirectInfo storage direct = userDirectInfo[msg.sender][directTime_];
        uint _t = directTime_;
        require(direct.lockReward != 0, "wrong time");

        if (block.timestamp >= direct.lastClaimTime) {
            return 0;
        }

        uint temp = updataUserDirectRewrd(msg.sender, _t);
        direct.lastClaimTime = block.timestamp;
        direct.claimed += temp;  

        if(temp > 1e13) {
            IERC20(tokenEMET).transfer(msg.sender, temp);
        }
        emit ClaimDirect(_t, msg.sender, temp);
        return temp;
    }

    function claimSynthesis(uint synTime_) public returns(uint){
        // UserInfo storage user = userInfo[msg.sender];
        SynthesisInfo storage synthe = userSynthesisInfo[msg.sender][synTime_];
        uint _t = synTime_;
        require(synthe.lockReward != 0, "wrong time");
    
        if (block.timestamp >= synthe.lastClaimTime) {
            return 0;
        }

        uint temp = updataUserSynthesisRewrd(msg.sender, _t);
        synthe.lastClaimTime = block.timestamp;
        synthe.claimed += temp;

        if(temp > 1e13) {
            IERC20(tokenEMET).transfer(msg.sender, temp);
        }

        emit ClaimSyn(_t, msg.sender, temp);
        return temp;
    }

    function updataUserDirectRewrd(address user_, uint time_) public view returns(uint temp) {
        DirectInfo storage direct = userDirectInfo[user_][time_];
        uint perDirect;
        if (block.timestamp >= direct.lastClaimTime) {
            return 0;
        }

        if (block.timestamp < direct.lockTime) {
            perDirect = (block.timestamp - direct.lastClaimTime) * 1e10 / direct.lockTime;
            temp += direct.lockReward * perDirect / 1e10;
        } else if (block.timestamp >= direct.lockTime) {
            perDirect = direct.lockReward - direct.claimed;     
            temp = perDirect;
        }
    }

    function updataUserSynthesisRewrd(address user_, uint time_)public view returns(uint temp){
        SynthesisInfo storage synthe = userSynthesisInfo[user_][time_];
        uint perSynthesis;
        if (block.timestamp < synthe.lockTime) {
            perSynthesis = (block.timestamp - synthe.lastClaimTime) * 1e10 / synthe.lockTime;
            temp += synthe.lockReward * perSynthesis / 1e10;
        } else if (block.timestamp >= synthe.lockTime) {
            perSynthesis = synthe.lockReward - synthe.claimed;
            temp = perSynthesis;
        }
    }

    function checkLimit(uint temp) internal pure returns(uint) {
        if(temp <= 1e13) {
            temp = 1e13 + 10000;
        }
        return temp;
    }

    // ---------------------------------  direct claim  ---------------------------------------
    function getCardToWallet(uint tokenId_) public {
        require(nftCardOwner[tokenId_] == msg.sender, "not your card");
        emetNFT.safeTransferFrom(address(this), _msgSender(),  tokenId_);
        _process(tokenId_);
    }

    event Direct(address indexed user, uint indexed cardId, uint indexed tokenId);
    function directDepositIt(uint tokenId_) public returns(bool) {
        UserInfo storage user = userInfo[msg.sender]; 
        uint cardId = emetNFT.cardIdMap(tokenId_);
        uint len = cardIds.length;
        uint pending;
        for(uint i=0; i<len; i++) {
            if (cardId == cardIds[i]) {
                pending = directRewards[i];
            }
        }
        // user.direct += pending;
        // user.lockTimeDirect = directLockTime;

        uint _time = block.timestamp;
        user.dirTimestamp.push(_time);
        userDirectInfo[msg.sender][_time] = DirectInfo({
            directTime : _time,
            level : cardId,
            lockTime : directLockTime,
            lockReward : pending,
            lastClaimTime : _time,
            claimed:0
        });

        _process(tokenId_);
        // emetNFT.safeTransferFrom(_msgSender(), address(this), tokenId_);
        emit Direct(msg.sender, cardId, tokenId_);
        return true;
    }

    function _process(uint tokenId_) internal {
        nftCardOwner[tokenId_] = address(0);
        uint _index;
        uint _length = userTokenIdList[msg.sender].length;
        for(uint i = 0; i < _length; i ++){
           if (userTokenIdList[msg.sender][i] == tokenId_) {
                _index = i;
                break;
           }
        }
        userTokenIdList[msg.sender][_index] = userTokenIdList[msg.sender][_length - 1];
        userTokenIdList[msg.sender].pop();
    }

    // ------------------------------------  synthesis  ----------------------------------------
    event Synthesis(address indexed user, uint indexed cardId, uint indexed Medal);
    function checkTokenIds(uint[] memory tokenIds_) internal view {
        uint len = tokenIds_.length;
        for(uint i=0; i<len; i++) {
            require(nftCardOwner[tokenIds_[i]] == msg.sender, "not your card");
        }
    }

    function synthesis(uint[] memory tokenIds_) public returns(uint medal, uint pack) {
        UserInfo storage user = userInfo[msg.sender]; 
        // checkTokenIds(tokenIds_);   
        uint len = tokenIds_.length;

        uint tempTime;
        uint cardId = emetNFT.cardIdMap(tokenIds_[0]);
        if (len == 5 && cardId == cardIds[0]) {
            pack = _synthesisA(tokenIds_);
            tempTime = syntheticLockTime[0];
            medal = 1;
        } else if (len == 4 && cardId == cardIds[1]) {
            pack = _synthesisB(tokenIds_);
            tempTime = syntheticLockTime[0];
            medal = 2;
        } else if (len == 3 && cardId == cardIds[2]) {
            pack = _synthesisC(tokenIds_);
            tempTime = syntheticLockTime[0];
            medal = 3;
        } else if (len == 2 && cardId == cardIds[3]) {
            pack = _synthesisD(tokenIds_);
            tempTime = syntheticLockTime[1];
        } else if (len == 2 && cardId == cardIds[4]) {
            pack = _synthesisE(tokenIds_);
            tempTime = syntheticLockTime[1];
        } else if (len == 2 && cardId == cardIds[5]) {
            pack = _synthesisF(tokenIds_);
            tempTime = syntheticLockTime[1];
        } else if (len == 2 && cardId == cardIds[6]) {
            pack = _synthesisG(tokenIds_);
            tempTime = syntheticLockTime[1];
        } else if (len == 1 && cardId == cardIds[7]) {
            pack = _synthesisH(tokenIds_[0]);
            tempTime = syntheticLockTime[1];
        }

        uint _time = block.timestamp;
        user.synTimestamp.push(_time);
        userSynthesisInfo[msg.sender][_time] = SynthesisInfo({
            synthesisTime : _time,
            level : cardId,
            lockTime : tempTime,
            lockReward : pack,
            lastClaimTime : _time,
            claimed:0
        });
        // for (uint i=0; i<len; i++){
        //     _process(tokenIds_[i]);
        // }

    }

    function _synthesisA(uint[] memory tokenIds_) internal returns(uint) {
        uint len = tokenIds_.length;
        require(len == 5, "wrong length");
        uint cardId;
        for(uint u=0; u<len; u++) {
            cardId = emetNFT.cardIdMap(tokenIds_[u]);
            require(cardId == cardIds[u], "not A card");
        }
        IERC20(tokenEMET).transferFrom(msg.sender, blackHole, costs[0]);

        for (uint i=0; i<len; i++){
            emetNFT.burn(tokenIds_[i]);
        }
        emetNFT.mint(msg.sender, idOfMedal[0]);
        emit Synthesis(_msgSender(), cardIds[0], idOfMedal[0]);
        return syntheticRewards[0];
    }

    function _synthesisB(uint[] memory tokenIds_) internal returns(uint) {
        uint len = tokenIds_.length;
        require(len == 4, "wrong length");
        uint cardId;
        for (uint u=0; u<len; u++) {
            cardId = emetNFT.cardIdMap(tokenIds_[u]);
            require(cardId == cardIds[u+1], "not B card");
        }
        IERC20(tokenEMET).transferFrom(msg.sender, blackHole, costs[1]);

        for (uint i=0; i<len; i++){
            emetNFT.burn(tokenIds_[i]);
        }
        emetNFT.mint(msg.sender, idOfMedal[1]);
        emit Synthesis(_msgSender(), cardIds[1], idOfMedal[1]);
        return syntheticRewards[1];
    }

    function _synthesisC(uint[] memory tokenIds_) internal returns(uint) {
        uint len = tokenIds_.length;
        require(len == 3, "wrong length");
        uint cardId;
        for (uint u=0; u<len; u++) {
            cardId = emetNFT.cardIdMap(tokenIds_[u]);
            require(cardId == cardIds[u+2], "not B card");
        }
        IERC20(tokenEMET).transferFrom(msg.sender, blackHole, costs[2]);

        for (uint i=0; i<len; i++){
            emetNFT.burn(tokenIds_[i]);
        }
        emetNFT.mint(msg.sender, idOfMedal[2]);
                emit Synthesis(_msgSender(), cardIds[2], idOfMedal[2]);
        return syntheticRewards[2];
    }

    function _synthesisD(uint[] memory tokenIds_) internal returns(uint) {
        uint len = tokenIds_.length;
        require(len == 2, "weong length");
        uint cardId_1 = emetNFT.cardIdMap(tokenIds_[0]);
        uint cardId_2 = emetNFT.cardIdMap(tokenIds_[1]);
        require(cardId_1 == cardIds[3] && cardId_2 == cardIds[7], "not D/H card");

        IERC20(tokenEMET).transferFrom(msg.sender, blackHole, costs[3]);

        for (uint i=0; i<len; i++){
            emetNFT.burn(tokenIds_[i]);
        }
        emit Synthesis(_msgSender(), cardIds[3], uint(0));
        return syntheticRewards[3];
    }

    function _synthesisE(uint[] memory tokenIds_) internal returns(uint) {
        uint len = tokenIds_.length;
        require(len == 2, "weong length");
        uint cardId_1 = emetNFT.cardIdMap(tokenIds_[0]);
        uint cardId_2 = emetNFT.cardIdMap(tokenIds_[1]);
        require(cardId_1 == cardIds[4] && cardId_2 == cardIds[7], "not E/H card");
        IERC20(tokenEMET).transferFrom(msg.sender, blackHole, costs[4]);

        for (uint i=0; i<len; i++){
            emetNFT.burn(tokenIds_[i]);
        }
        emit Synthesis(_msgSender(), cardIds[4], uint(0));
        return syntheticRewards[4];
    }

    function _synthesisF(uint[] memory tokenIds_) internal returns(uint) {
        uint len = tokenIds_.length;
        require(len == 2, "weong length");
        uint cardId_1 = emetNFT.cardIdMap(tokenIds_[0]);
        uint cardId_2 = emetNFT.cardIdMap(tokenIds_[1]);
        require(cardId_1 == cardIds[5] && cardId_2 == cardIds[7], "not F/H card");
        IERC20(tokenEMET).transferFrom(msg.sender, blackHole, costs[5]);

        for (uint i=0; i<len; i++){
            emetNFT.burn(tokenIds_[i]);
        }
        emit Synthesis(_msgSender(), cardIds[5], uint(0));
        return syntheticRewards[5];
    }

    function _synthesisG(uint[] memory tokenIds_) internal returns(uint) {
        uint len = tokenIds_.length;
        require(len == 2, "weong length");
        uint cardId_1 = emetNFT.cardIdMap(tokenIds_[0]);
        uint cardId_2 = emetNFT.cardIdMap(tokenIds_[1]);
        require(cardId_1 == cardIds[6] && cardId_2 == cardIds[7], "not G/H card");
        IERC20(tokenEMET).transferFrom(msg.sender, blackHole, costs[6]);

        for (uint i=0; i<len; i++){
            emetNFT.burn(tokenIds_[i]);
        }
        emit Synthesis(_msgSender(), cardIds[6], uint(0));
        return syntheticRewards[6];
    }

    function _synthesisH(uint tokenId_) internal returns(uint) {
        uint cardId = emetNFT.cardIdMap(tokenId_);
        require(cardId == cardIds[7], "not H card");
        IERC20(tokenEMET).transferFrom(msg.sender, blackHole, costs[7]);
        emetNFT.burn(tokenId_);
        emit Synthesis(_msgSender(), cardIds[7], uint(0));
        return syntheticRewards[7];
    }

    // ----------------------------------  synthesis  ---------------------------------------
    function checkLockTime() public view returns(uint _directLockTime, uint[2] memory _syntheticLockTime){
        _directLockTime = directLockTime;
        _syntheticLockTime = syntheticLockTime;
    }

    function userCardInBank(address user_) public view returns(uint[] memory, uint[] memory, string[] memory){
        uint len = userTokenIdList[user_].length;
        uint[] memory _tokenIds = new uint[](len);
        uint[] memory _cardIds = new uint[](len);
        string[] memory _tokenUrls = new string[](len);
        uint _tokenId;
        for(uint i=0; i<len; i++) {
            _tokenId = userTokenIdList[user_][i];
            _tokenIds[i] =  _tokenId;
            _tokenUrls[i] = emetNFT.tokenURI(_tokenId);
            _cardIds[i] = emetNFT.cardIdMap(_tokenId);
        }
        return(_tokenIds, _cardIds, _tokenUrls);
    }
    
    function userTimestamp(address user_) public view returns(uint[] memory directList, uint[] memory synthesisList) {
        UserInfo storage user = userInfo[user_];    
        uint len1 = user.dirTimestamp.length;
        uint len2 = user.synTimestamp.length;
        directList = new uint[](len1);
        synthesisList = new uint[](len2);
        for(uint i=0; i<len1; i++) {
            directList[i] = user.dirTimestamp[i];
        }
        for(uint x=0; x<len1; x++) {
            directList[x] = user.synTimestamp[x]; 
        }
    }

    function checkUserSynthesisRecord(address user_) public view returns(
    uint[] memory _synthesisList,
    uint[] memory _level, 
    uint[] memory _lastClaimTime,
    uint[] memory _lockTime, 
    uint[] memory _lockReward, 
    uint[] memory _claimed,
    uint[] memory _toClaim ) {
        UserInfo storage user = userInfo[user_];    

        uint len1 = user.synTimestamp.length;
        uint _time;
        _synthesisList = new uint[](len1);
        _level = new uint[](len1);
        _lastClaimTime = new uint[](len1);
        _lockTime = new uint[](len1);
        _lockReward = new uint[](len1);
        _claimed = new uint[](len1);
        _toClaim = new uint[](len1);

        for(uint i=0; i<len1; i++) {
            _time = user.synTimestamp[i];
            _synthesisList[i] = _time;

            _level[i] = userSynthesisInfo[user_][_time].level;
            _lastClaimTime[i] = userSynthesisInfo[user_][_time].lastClaimTime;
            _lockTime[i] = userSynthesisInfo[user_][_time].lockTime;
            _lockReward[i] = userSynthesisInfo[user_][_time].lockReward;
            _claimed[i] = userSynthesisInfo[user_][_time].claimed;
            _toClaim[i] = updataUserSynthesisRewrd(user_, _time);
        }
        return(_synthesisList, _level, _lastClaimTime, _lockTime, _lockReward, _claimed, _toClaim);
    }

    function checkUserDirectRecord(address user_) public view returns(
    uint[] memory _directList, 
    uint[] memory _level, 
    uint[] memory _lastClaimTime,
    uint[] memory _lockTime, 
    uint[] memory _lockReward, 
    uint[] memory _claimed,
    uint[] memory _toClaim ) {
        UserInfo storage user = userInfo[user_];
        uint _time;    
        uint len1 = user.dirTimestamp.length;
        _directList = new uint[](len1);
        _level = new uint[](len1);
        _lastClaimTime = new uint[](len1);
        _lockTime = new uint[](len1);
        _lockReward = new uint[](len1);
        _claimed = new uint[](len1);
        _toClaim = new uint[](len1);
        for(uint i=0; i<len1; i++) {
            _time = user.dirTimestamp[i];
            _directList[i] = _time;

            _level[i] = userDirectInfo[user_][_time].level;
            _lastClaimTime[i] = userDirectInfo[user_][_time].lastClaimTime;
            _lockTime[i] = userDirectInfo[user_][_time].lockTime;
            _lockReward[i] = userDirectInfo[user_][_time].lockReward;
            _claimed[i] = userDirectInfo[user_][_time].claimed;
            _toClaim[i] = updataUserDirectRewrd(user_, _time);
        }

        return(_directList, _level, _lastClaimTime, _lockTime, _lockReward, _claimed, _toClaim);
    }

    function sortLevel(uint[] memory tokenIds_) public view returns(uint[] memory cardIds_) {
        uint len = tokenIds_.length;
        cardIds_ = new uint[](len);
        for(uint i=0; i<len; i++) {
            cardIds_[i] = emetNFT.cardIdMap(tokenIds_[i]);
        }
        return cardIds_;
    }

    function checkCostAndRewarad(uint[] memory tokenIds_) public view returns(uint cost, uint pack, uint medal) { 
        uint len = tokenIds_.length;
        uint cardId = emetNFT.cardIdMap(tokenIds_[0]);
        if (len == 5 && cardId == cardIds[0]) {
            cost = costs[0];
            pack = syntheticRewards[0];
            medal =1;
        } else if (len == 4 && cardId == cardIds[1]) {
            cost = costs[1];
            pack = syntheticRewards[1];
            medal = 2;
        } else if (len == 3 && cardId == cardIds[2]) {
            cost = costs[2];
            pack = syntheticRewards[2];
            medal = 3;
        } else if (len == 2 && cardId == cardIds[3]) {
            cost = costs[3];
            pack = syntheticRewards[3];
        } else if (len == 2 && cardId == cardIds[4]) {
            cost = costs[4];
            pack = syntheticRewards[4];
        } else if (len == 2 && cardId == cardIds[5]) {
            cost = costs[5];
            pack = syntheticRewards[5];
        } else if (len == 2 && cardId == cardIds[6]) {
            cost = costs[6];
            pack = syntheticRewards[6];
        } else if (len == 1 && cardId == cardIds[7]) {
            cost = costs[7];
            pack = syntheticRewards[7];
        } else {
            cost = 0;
            pack = 0;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomGenerator {
    uint private randNonce = 0;

    function random(uint256 seed) internal returns (uint256) {
        randNonce += 1;
        return uint256(keccak256(abi.encodePacked(
                blockhash(block.number - 1),
                blockhash(block.number - 2),
                blockhash(block.number - 3),
                blockhash(block.number - 4),
                blockhash(block.number - 5),
                blockhash(block.number - 6),
                blockhash(block.number - 7),
                blockhash(block.number - 8),
                block.timestamp,
                msg.sender,
                randNonce,
                seed
            )));
    }

    function randomCeil(uint256 q) internal returns (uint256) {
        return (random(gasleft()) % q) + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract EMET_NFT is Ownable, ERC721Enumerable, ERC721URIStorage {
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct CardInfo {
        uint cardId;
        string name;
        uint currentAmount;
        uint burnedAmount;
        uint maxAmount;
        string tokenURI;
    }

    mapping (address => bool) public superMinters;
    mapping(uint => CardInfo) public cardInfoes;  
    mapping(uint => uint) public cardIdMap;
    mapping(address => mapping(uint => uint)) public minters;
    address public superMinter;
    string public myBaseURI;
    uint public burned;
    

    // for inherit
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        ERC721._burn(tokenId);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC721Enumerable).interfaceId
        || interfaceId == type(IERC721Metadata).interfaceId
        || super.supportsInterface(interfaceId);
    }

    function setTokenId(uint number_) public onlyOwner {
        for (uint i = 0; i < number_; i++) {
            _tokenIds.increment();
        }
    }

    function setSuperMinter(address newSuperMinter_, bool b) public onlyOwner returns (bool) {
        superMinters[newSuperMinter_] = b;
        return true;
    }

    function setMinterBatch(address newMinter_, uint[] calldata ids_, uint[] calldata amounts_) public onlyOwner returns (bool) {
        require(ids_.length > 0 && ids_.length == amounts_.length,"ids and amounts length mismatch");
        for (uint i = 0; i < ids_.length; ++i) {
            minters[newMinter_][ids_[i]] = amounts_[i];
        }
        return true;
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

    constructor(string memory name_, string memory symbol_, string memory myBaseURI_) ERC721(name_, symbol_) {
        myBaseURI = myBaseURI_;
        superMinter = msg.sender;
    }

    function setMyBaseURI(string calldata uri_) public onlyOwner {
        myBaseURI = uri_;
    }

    event NewCard(uint indexed cardId, uint indexed maxAmount);
    function newCard(string calldata name_, uint cardId_, uint maxAmount_, string calldata tokenURI_) public onlyOwner {
        require(cardId_ != 0 && cardInfoes[cardId_].cardId == 0, "K: wrong cardId");

        cardInfoes[cardId_] = CardInfo({
        cardId : cardId_,
        name : name_,
        currentAmount : 0,
        burnedAmount : 0,
        maxAmount : maxAmount_,
        tokenURI : tokenURI_
        });
    }

    function newCardMulti(string[] calldata names_, uint[] calldata cardIds_, uint[] calldata maxAmounts_, string[] calldata tokenURIs_)public onlyOwner {
        // require(cardId_ != 0 && cardInfoes[cardId_].cardId == 0, "K: wrong cardId");
        uint len = cardIds_.length;
        for (uint i=0; i<len; i++) {
            newCard(names_[i], cardIds_[i], maxAmounts_[i], tokenURIs_[i]);
        }
    }


    function newBurnedCard(string calldata name_, uint cardId_, uint maxAmount_, string calldata tokenURI_, uint burnedAmount_) public onlyOwner {
        require(cardId_ != 0 && cardInfoes[cardId_].cardId == 0, "K: wrong cardId");

        cardInfoes[cardId_] = CardInfo({
        cardId : cardId_,
        name : name_,
        currentAmount : burnedAmount_,
        burnedAmount : burnedAmount_,
        maxAmount : maxAmount_,
        tokenURI : tokenURI_
        });
    }

    // 编辑卡片
    function editCard(string calldata name_, uint cardId_, uint maxAmount_, string calldata tokenURI_) public onlyOwner {
        require(cardId_ != 0 && cardInfoes[cardId_].cardId == cardId_, "K: wrong cardId");

        cardInfoes[cardId_] = CardInfo({
        cardId : cardId_,
        name : name_,
        currentAmount : cardInfoes[cardId_].currentAmount,
        burnedAmount : cardInfoes[cardId_].burnedAmount,
        maxAmount : maxAmount_,
        tokenURI : tokenURI_
        });
    }

    // 
    function getNextTokenId() public returns(uint) {
       _tokenIds.increment();
       return  _tokenIds.current();
    }
   
    // 铸造
    function mint(address player_, uint cardId_) public returns (uint) {
        require(cardId_ != 0 && cardInfoes[cardId_].cardId != 0, "K: wrong cardId");

        if (superMinter != _msgSender() || !superMinters[_msgSender()]) {
            require(minters[_msgSender()][cardId_] > 0, "K: not minter");
            minters[_msgSender()][cardId_] -= 1;
        }

        require(cardInfoes[cardId_].currentAmount < cardInfoes[cardId_].maxAmount, "k: amount out of limit");
        cardInfoes[cardId_].currentAmount += 1;

        uint tokenId = getNextTokenId();
        cardIdMap[tokenId] = cardId_;
        _safeMint(player_, tokenId);

        return tokenId;
    }

    // 批量铸造-1
    function mintMulti(address player_, uint cardId_, uint amount_) public returns (uint[] memory) {
        require(amount_ > 0, "K: missing amount");
        require(cardId_ != 0 && cardInfoes[cardId_].cardId != 0, "K: wrong cardId");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()][cardId_] >= amount_, "K: not minter");
            minters[_msgSender()][cardId_] -= amount_;
        }

        require(cardInfoes[cardId_].maxAmount - cardInfoes[cardId_].currentAmount >= amount_, "K: amount out of limit");
        cardInfoes[cardId_].currentAmount += amount_;

        uint tokenId;
        uint[] memory info = new uint[](amount_);
        for (uint i = 0; i < amount_; ++i) {
            tokenId = getNextTokenId();
            cardIdMap[tokenId] = cardId_;
            _safeMint(player_, tokenId);
            info[i] = tokenId;
        }
        return info;
    }

    // 批量铸造-2
    function mintBatch(address player_, uint[] calldata ids_, uint[] calldata amounts_) public returns (bool) {
        require(ids_.length > 0 && ids_.length == amounts_.length, "length mismatch");
        for (uint i = 0; i < ids_.length; ++i) {
            mintMulti(player_, ids_[i], amounts_[i]);
        }
        return true;
    }

    // 销毁
    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "K: burner isn't owner");

        uint cardId = cardIdMap[tokenId_];
        cardInfoes[cardId].burnedAmount += 1;
        burned += 1;

        _burn(tokenId_);
        return true;
    }

    // 批量销毁
    function burnMulti(uint[] calldata tokenIds_) public returns (bool) {
        for (uint i = 0; i < tokenIds_.length; ++i) {
            burn(tokenIds_[i]);
        }
        return true;
    }

    function exists(uint tokenId_) public view returns (bool) {
        return _exists(tokenId_);
    }

    // 查看某个tokenid 的 tokenUrls
    function tokenURI(uint tokenId_) override(ERC721URIStorage, ERC721) public view returns (string memory) {
        require(_exists(tokenId_), "K: nonexistent token");

        return string(abi.encodePacked(_myBaseURI(), '/', cardInfoes[cardIdMap[tokenId_]].tokenURI));
    }

    // 查看地址的所有tokenUrls
    function batchTokenURI(address account_) public view returns (string[] memory) {
        uint amount = balanceOf(account_);
        uint tokenId;
        string[] memory info = new string[](amount);
        for (uint i = 0; i < amount; i++) {
            tokenId = tokenOfOwnerByIndex(account_, i);
            info[i] = tokenURI(tokenId);
        }
        return info;
    }

    // 查看 baseUrl
    function _myBaseURI() internal view returns (string memory) {
        return myBaseURI;
    }


    function tokenOfOwnerForAll(address addr_) public view returns(uint[] memory, uint[] memory) {
        uint len = balanceOf(addr_);
        uint id;
        uint[] memory _TokenIds = new uint[](len);
        uint[] memory _CardIds = new uint[](len);
        for(uint i=0; i<len;i++) {
            id = tokenOfOwnerByIndex(addr_, i);
            _TokenIds[i] = id;
            _CardIds[i] = cardIdMap[id];
        }
        return (_TokenIds, _CardIds);

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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