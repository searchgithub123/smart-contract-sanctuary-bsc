// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./Interfaces.sol";

// Labo management is where labo owner will create potion with credit
// Credit come from workers in labo and time passed in
// workers are Zais who want to be sorceler , when a Zai work in spot in a Labo, he will gain mana 
contract LaboManagement is ERC721Holder, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint256 => EnumerableSet.UintSet) private laboUnsoldPotions;
    mapping(uint256 => EnumerableSet.UintSet) private laboSoldPotions;

    event PotionSold(address indexed labOwner, uint256 price);

    uint256 public workingSpotPrice = 200000 * 1E18;

    // a Labo can't have infinite credit, it is capped
    // owner have to come and create potion to use credit of labo
    uint256 public maxCredit = 2000000;

    uint256 public pointCreditCost = 10000;

    IERC20 public BZAI;
    IAddresses public gameAddresses;

    constructor(address _BZAI) {
        BZAI = IERC20(_BZAI);
    }

    mapping(uint256 => uint256) public laboratoryRevenues;
    mapping(uint256 => uint256) _potionsCredits; // On front end for update credits:
    mapping(uint256 => uint256) public createdPotionsForLab;

    // stored for futur rewards
    mapping(uint256 => uint256) public zaiNumberOfWork;
    mapping(address => uint256) public userNumberOfWork;

    struct WorkInstance {
        uint256 zaiId;
        uint256 beginingAt;
    }

    mapping(uint256 => mapping(uint256 => WorkInstance)) public workingSpot;
    mapping(uint256 => uint256) public employees;

    modifier onlyLaboOwner(uint256 _laboId) {
        require(
            ILaboratory(gameAddresses.getLaboratoryNFTAddress()).ownerOf(
                _laboId
            ) == msg.sender
        );
        _;
    }

    modifier canUseZai(uint256 _zaiId) {
        require(
            IDelegate(gameAddresses.getDelegateZaiAddress()).canUseZai(
                _zaiId,
                msg.sender
            ),
            "Not your zai nor delegated"
        );
        _;
    }

    function setGameAddresses(address _gameAddress) external onlyOwner {
        require(gameAddresses == IAddresses(address(0x0)));
        gameAddresses = IAddresses(_gameAddress);
    }

    function setPointCreditCost(uint256 _cost) external onlyOwner {
        pointCreditCost = _cost;
    }

    function setMaxCredit(uint256 _credit) external onlyOwner {
        require(_credit >= 1000000 && _credit <= 10000000, "Not a good value");
        maxCredit = _credit;
    }

    function setWorkingSpotPrice(uint256 _price) public onlyOwner {
        workingSpotPrice = _price;
    }

    function addWorkingSpotToLab(uint256 _laboId)
        external
        onlyLaboOwner(_laboId)
        returns (bool)
    {
        ILaboratory I = ILaboratory(gameAddresses.getLaboratoryNFTAddress());
        require(I.numberOfWorkingSpots(_laboId) <= 9, "Max spots already hit");

        IPayments IPay = IPayments(gameAddresses.getPaymentsAddress());
        require(IPay.payWithRewardOrWallet(msg.sender, workingSpotPrice));
        IPay.distributeFees(workingSpotPrice);

        return I.updateNumberOfWorkingSpots(_laboId);
    }

    function workInASpot(
        uint256 _zaiId,
        uint256 _laboId,
        uint256 _spotId
    ) external canUseZai(_zaiId) {
        IZaiNFT IZai = IZaiNFT(gameAddresses.getZaiAddress());
        ILaboratory ILab = ILaboratory(gameAddresses.getLaboratoryNFTAddress());

        require(
            ILab.ownerOf(_laboId) != gameAddresses.getClaimNFTsAddress(),
            "Lab not active"
        );
        require(IZai.isFree(_zaiId), "Not Free");
        require(
            ILab.numberOfWorkingSpots(_laboId) >= _spotId,
            "Not enough spots"
        );
        WorkInstance storage w = workingSpot[_laboId][_spotId];
        require(
            w.zaiId == 0 || block.timestamp > w.beginingAt + 1 days,
            "Spot not free"
        );
        // preventing bot attack by randomize a revert transaction during first hour after 24h of work for a Zai
        if (block.timestamp < w.beginingAt + 1 days + 3600) {
            require(
                IOracle(gameAddresses.getOracleAddress()).getRandom(
                    keccak256(
                        abi.encodePacked(_zaiId, block.timestamp, msg.sender)
                    )
                ) %
                    100 <
                    5,
                "Bot prevention only 5% chance in those 60 min"
            );
        }

        _updateCredits(_laboId);

        if (w.zaiId != 0) {
            require(
                _updateZai(
                    w.zaiId,
                    _getManaWon(block.timestamp, w.beginingAt),
                    true
                )
            );
        } else {
            employees[_laboId] += 1;
        }
        w.zaiId = _zaiId;
        w.beginingAt = block.timestamp;
        IZaiMeta(gameAddresses.getZaiMetaAddress()).updateStatus(
            _zaiId,
            3,
            _laboId
        );
    }

    function stopWorking(
        uint256 _zaiId,
        uint256 _laboId,
        uint256 _spotId
    ) external canUseZai(_zaiId) {
        WorkInstance storage w = workingSpot[_laboId][_spotId];
        require(w.zaiId == _zaiId, "Not your zai");
        require(
            _updateZai(
                w.zaiId,
                _getManaWon(block.timestamp, w.beginingAt),
                (block.timestamp - w.beginingAt > 1 days)
            )
        );
        w.beginingAt = 0;
        w.zaiId = 0;
        employees[_laboId] -= 1;
        _updateCredits(_laboId);
    }

    function _getManaWon(uint256 _finished, uint256 _start)
        internal
        pure
        returns (uint256 mana)
    {
        uint256 _duration = _finished - _start;
        if (_duration <= 21600) {
            // less than 6 h
            mana = 0;
        } else if (_duration <= 43200) {
            // less than 12h
            mana = 500;
        } else if (_duration <= 86400) {
            // less than 24h
            mana = 1000;
        } else if (_duration <= 129600) {
            // less than 36h
            mana = 2000;
        } else {
            mana = 3000;
        }
    }

    // manaMax is the maximum a Zai can store in mana
    // to increase manaMax, a Zai must finish at least 24h of work in a spot
    // a Zai can't have more than 10k of manamax
    function _updateZai(
        uint256 _zaiId,
        uint256 _mana,
        bool _manaMaxUpgrade
    ) internal returns (bool) {
        IZaiMeta I = IZaiMeta(gameAddresses.getZaiMetaAddress());
        I.updateStatus(_zaiId, 0, 0);
        if (_manaMaxUpgrade) {
            zaiNumberOfWork[_zaiId] += 1;
            userNumberOfWork[
                IZaiNFT(gameAddresses.getZaiAddress()).ownerOf(_zaiId)
            ] += 1;
        }

        return (
            I.updateMana(
                _zaiId,
                _mana,
                0,
                // 2 first work give 1000 manaMax. next give 100
                _manaMaxUpgrade ? zaiNumberOfWork[_zaiId] <= 2 ? 1000 : 100 : 0
            )
        );
    }

    function getCredit(uint256 _laboId) external view returns (uint256) {
        return _getCredit(_laboId);
    }

    function _getCredit(uint256 _laboId)
        internal
        view
        returns (uint256 credits)
    {
        uint256 _creditLastUpdate = ILaboratory(
            gameAddresses.getLaboratoryNFTAddress()
        ).getCreditLastUpdate(_laboId);

        if (_creditLastUpdate == 0) {
            credits = 0;
        } else {
            uint256 _timePassed = block.timestamp - _creditLastUpdate;
            if (employees[_laboId] > 0) {
                credits =
                    _potionsCredits[_laboId] +
                    (_timePassed * employees[_laboId]);
                if (credits > maxCredit) {
                    credits = maxCredit;
                }
            } else {
                credits = _potionsCredits[_laboId] + (_timePassed / 4);
            }
        }
    }

    function createAndSellPotion(
        uint256 _quantity,
        uint256 _price,
        uint256 _type,
        uint256 _power,
        uint256 _laboId
    ) external onlyLaboOwner(_laboId) returns (bool) {
        require(_type < 5 || _type == 8, "not good potion");
        require(_quantity <= 5, "Only 5 potions max can be created by tx");
        require(
            IOpenAndClose(gameAddresses.getOpenAndCloseAddress()).canLaboSell(
                _laboId
            ),
            "You can't"
        );
        _updateCredits(_laboId);
        require(
            _potionsCredits[_laboId] >= (_quantity * _power * pointCreditCost),
            "Not enough credits"
        );

        _potionsCredits[_laboId] -= (_quantity * _power * pointCreditCost);
        createdPotionsForLab[_laboId] += _quantity;
        IPotions potion = IPotions(gameAddresses.getPotionAddress());

        for (uint256 i = 0; i < _quantity; ) {
            uint256 potionId = potion.mintPotionForSale(
                _laboId,
                _price,
                _type,
                _power
            );
            EnumerableSet.add(laboUnsoldPotions[_laboId], potionId);
            unchecked {
                ++i;
            }
        }

        return true;
    }

    function changePotionPrice(
        uint256 _potionId,
        uint256 _laboId,
        uint256 _price
    ) external onlyLaboOwner(_laboId) returns (bool) {
        return
            IPotions(gameAddresses.getPotionAddress()).changePotionPrice(
                _potionId,
                _laboId,
                _price
            );
    }

    function getUnsoldPotions(uint256 _laboId)
        external
        view
        returns (PotionStruct.Potion[] memory)
    {
        uint256 unSoldNumber = EnumerableSet.length(laboUnsoldPotions[_laboId]);
        PotionStruct.Potion[] memory unSoldPotions = new PotionStruct.Potion[](
            unSoldNumber
        );
        IPotions potions = IPotions(gameAddresses.getPotionAddress());

        for (uint256 i = 0; i < unSoldNumber; ) {
            uint256 potionId = EnumerableSet.at(laboUnsoldPotions[_laboId], i);
            PotionStruct.Potion memory p = potions.getFullPotion(potionId);
            unSoldPotions[i] = p;
            unchecked {
                ++i;
            }
        }
        return unSoldPotions;
    }

    function getLast10soldPotions(uint256 _laboId)
        external
        view
        returns (PotionStruct.Potion[] memory)
    {
        uint256 soldNumber = EnumerableSet.length(laboSoldPotions[_laboId]);
        PotionStruct.Potion[] memory soldPotions = new PotionStruct.Potion[](
            10
        );
        IPotions potions = IPotions(gameAddresses.getPotionAddress());

        if (soldNumber == 0) {
            return soldPotions;
        } else if (soldNumber <= 10) {
            for (uint256 i = 0; i < soldNumber; ) {
                uint256 potionId = EnumerableSet.at(
                    laboSoldPotions[_laboId],
                    i
                );
                soldPotions[i] = potions.getFullPotion(potionId);
                unchecked {
                    ++i;
                }
            }
            return soldPotions;
        } else {
            for (uint256 i = soldNumber - 10; i < soldNumber; ) {
                uint256 potionId = EnumerableSet.at(
                    laboSoldPotions[_laboId],
                    i
                );
                soldPotions[soldNumber - i - 1] = potions.getFullPotion(
                    potionId
                );
                unchecked {
                    ++i;
                }
            }
            return soldPotions;
        }
    }

    // offering potion (to owner or anybody) cost 2 x the pointCredit needs 
    function offerPotion(
        uint256 _type,
        uint256 _power,
        uint256 _laboId,
        address _to
    ) external onlyLaboOwner(_laboId) returns (uint256) {
        require(_type < 5 || _type == 8, "not good potion");
        require(
            IOpenAndClose(gameAddresses.getOpenAndCloseAddress()).canLaboSell(
                _laboId
            ),
            "You can't"
        );
        _updateCredits(_laboId);
        require(
            _potionsCredits[_laboId] >= (_power * 2 * pointCreditCost),
            "Not enough credits"
        );
        _potionsCredits[_laboId] -= (_power * 2 * pointCreditCost);
        createdPotionsForLab[_laboId] += 1;

        return
            IPotions(IAddresses(gameAddresses).getPotionAddress()).offerPotion(
                _type,
                _power,
                _to
            );
    }

    function buyPotions(
        uint256[] memory _potionsIds,
        uint256[] memory _maxPrice
    ) external {
        for (uint256 i = 0; i < _potionsIds.length; ) {
            buyPotion(_potionsIds[i], _maxPrice[i]);
            unchecked {
                ++i;
            }
        }
    }

    function buyPotion(uint256 _potionId, uint256 _maxPrice) public {
        address _potionAddress = gameAddresses.getPotionAddress();
        require(
            IERC721(_potionAddress).ownerOf(_potionId) == address(this),
            "Not in sale"
        );

        PotionStruct.Potion memory p = IPotions(_potionAddress).getFullPotion(
            _potionId
        );

        IPayments IPay = IPayments(gameAddresses.getPaymentsAddress());

        require(_maxPrice >= p.listingPrice, "Price changed");

        require(IPay.payWithRewardOrWallet(msg.sender, p.listingPrice));
        IPay.payOwner(p.seller, p.listingPrice);

        emit PotionSold(p.seller, p.listingPrice);

        require(IPotions(_potionAddress).updatePotionSaleTimestamp(_potionId));

        laboratoryRevenues[p.fromLab] =
            laboratoryRevenues[p.fromLab] +
            p.listingPrice;
        EnumerableSet.remove(laboUnsoldPotions[p.fromLab], _potionId);
        EnumerableSet.add(laboSoldPotions[p.fromLab], _potionId);

        IERC721(_potionAddress).transferFrom(
            address(this),
            msg.sender,
            _potionId
        );
    }

    // used to prevent Zai locked in a "work" instance when a labo is in close process
    function cleanSlotsBeforeClosing(uint256 _laboId) external returns (bool) {
        require(
            msg.sender == gameAddresses.getOpenAndCloseAddress(),
            "Not authorized to clean"
        );
        if (employees[_laboId] == 0) {
            return true;
        } else {
            uint256 numberOfSpots = ILaboratory(
                gameAddresses.getLaboratoryNFTAddress()
            ).numberOfWorkingSpots(_laboId);
            for (uint256 i = 1; i <= numberOfSpots; ) {
                WorkInstance storage w = workingSpot[_laboId][i];
                if (w.zaiId != 0) {
                    bool _manaMaxUpgrade = block.timestamp - w.beginingAt >
                        1 days;
                    require(
                        _updateZai(
                            w.zaiId,
                            _getManaWon(block.timestamp, w.beginingAt),
                            _manaMaxUpgrade
                        )
                    );
                    w.beginingAt = 0;
                    w.zaiId = 0;
                    employees[_laboId] -= 1;
                    if (employees[_laboId] == 0) {
                        break;
                    }
                }
                unchecked {
                    ++i;
                }
            }
            return true;
        }
    }

    function _updateCredits(uint256 _laboId) internal {
        uint256 _credit = _getCredit(_laboId);
        require(
            ILaboratory(gameAddresses.getLaboratoryNFTAddress())
                .updateCreditLastUpdate(_laboId)
        );
        _potionsCredits[_laboId] = _credit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ZaiStruct {
    // Zai powers
    struct Powers {
        uint256 water;
        uint256 fire;
        uint256 metal;
        uint256 air;
        uint256 stone;
    }

    // A zai can work in a center , training or coaching. He can't fight if he isn't free
    //string[4] _status = ["Free","Training","Coaching","Working"];
    struct Activity {
        uint256 statusId;
        uint256 onCenter;
    }

    struct ZaiMetaData {
        uint256 state; // _states index
        uint256 ipfsPathId;
        uint256 seasonOf;
        bool isGod;
    }

    struct Zai {
        uint256 xp;
        uint256 manaMax;
        uint256 mana;
        uint256 level;
        uint256 creditForUpgrade; // credit to use to raise powers
        string name;
        Powers powers;
        Activity activity;
        ZaiMetaData metadata;
    }

    struct Stats {
        uint256 zaiTotalWins;
        uint256 zaiTotalDraw;
        uint256 zaiTotalLoss;
        uint256 zaiTotalFights;
    }

    struct EggsPrices {
        uint256 bronzePrice;
        uint256 silverPrice;
        uint256 goldPrice;
        uint256 platinumPrice;
    }

    struct MintedData {
        uint256 bronzeMinted;
        uint256 silverMinted;
        uint256 goldMinted;
        uint256 platinumMinted;
    }

    struct WorkInstance {
        uint256 zaiId;
        uint256 beginingAt;
    }

    struct DelegateData {
        address scholarAddress;
        address ownerAddress;
        uint256 contractDuration;
        uint256 contractEnd;
        uint256 percentageForScholar;
        uint256 lastScholarPlayed;
        bool renewable;
    }

    struct GuildeDatas {
        address renterOf;
        address masterOf;
        address platformAddress;
        uint256 percentageForScholar;
        uint256 percentageForGuilde;
        uint256 percentagePlatformFees;
    }

    struct ScholarDatas {
        GuildeDatas guildeDatas;
        DelegateData delegateDatas;
    }
}

library PotionStruct {
    struct Powers {
        uint256 water;
        uint256 fire;
        uint256 metal;
        uint256 air;
        uint256 stone;
        uint256 rest;
        uint256 xp;
        uint256 mana;
    }

    struct Potion {
        Powers powers;
        uint256 potionType; // 0: water ; 1: fire ; 2:metal ; 3:air ; 4:stone  ; 5:rest ; 6:xp ; 7:multiple ; 99 : empty
        address seller;
        uint256 listingPrice;
        uint256 fromLab;
        uint256 potionId;
        uint256 saleTimestamp;
    }
}

interface IOracle {
    function getRandom(bytes32 _id) external returns (uint256);
}

interface IZaiMeta {
    function getZaiURI(uint256 tokenId) external view returns (string memory);

    function createZaiDatas(
        uint256 _newItemId,
        string memory _name,
        uint256 _state,
        address _to,
        uint256 _level
    ) external;

    function getZai(uint256 _tokenId)
        external
        view
        returns (ZaiStruct.Zai memory);

    function getZaiState(uint256 _tokenId)
        external
        view
        returns (string memory);

    function getStatus(uint256 _tokenId)
        external
        view
        returns (uint256[2] memory);

    function isFree(uint256 _tokenId) external view returns (bool);

    function updateStatus(
        uint256 _tokenId,
        uint256 _newStatusID,
        uint256 _center
    ) external;

    function updateXp(uint256 _id, uint256 _xp)
        external
        returns (uint256 level);

    function updateMana(
        uint256 _tokenId,
        uint256 _manaUp,
        uint256 _manaDown,
        uint256 _maxUp
    ) external returns (bool);

    function getNextLevelUpPoints(uint256 _level)
        external
        view
        returns (uint256);
}

interface IZaiNFT is IERC721Enumerable {
    function mintZai(
        address _to,
        string memory _name,
        uint256 _state
    ) external returns (uint256);

    function createNewChallenger() external returns (uint256);

    function isFree(uint256 _tokenId) external view returns (bool);

    function getZai(uint256 _tokenId)
        external
        view
        returns (ZaiStruct.Zai memory);

    function getNextLevelUpPoints(uint256 _level)
        external
        view
        returns (uint256);
}

interface IipfsIdStorage {
    function getTokenURI(
        uint256 _season,
        uint256 _state,
        uint256 _id
    ) external view returns (string memory);

    function getNextIpfsId(uint256 _state, uint256 _nftId)
        external
        returns (uint256);

    function getCurrentSeason() external view returns (uint256);
}

interface ILaboratory is IERC721Enumerable {
    function mintLaboratory(address _to) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function getCreditLastUpdate(uint256 _tokenId)
        external
        view
        returns (uint256);

    function updateCreditLastUpdate(uint256 _tokenId) external returns (bool);

    function numberOfWorkingSpots(uint256 _tokenId)
        external
        view
        returns (uint256);

    function updateNumberOfWorkingSpots(uint256 _tokenId)
        external
        returns (bool);

    function getPreMintNumber() external view returns (uint256);
}

interface ILabManagement {
    function createdPotionsForLab(uint256 _tokenId)
        external
        view
        returns (uint256);

    function laboratoryRevenues(uint256 _tokenId)
        external
        view
        returns (uint256);

    function getCredit(uint256 _laboId) external view returns (uint256);

    function workingSpot(uint256 _laboId, uint256 _slotId)
        external
        view
        returns (ZaiStruct.WorkInstance memory);

    function cleanSlotsBeforeClosing(uint256 _laboId) external returns (bool);
}

interface IBZAI is IERC20 {
    function burn(uint256 _amount) external returns (bool);
}

interface ITraining is IERC721Enumerable {
    function mintTrainingCenter(address _to) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function numberOfTrainingSpots(uint256 _tokenId)
        external
        view
        returns (uint256);

    function addTrainingSpots(uint256 _tokenId, uint256 _amount)
        external
        returns (bool);

    function getPreMintNumber() external view returns (uint256);
}

interface ITrainingManagement {
    function cleanSlotsBeforeClosing(uint256 _laboId) external returns (bool);

    function getZaiLastTrainBegining(uint256 _zaiId)
        external
        view
        returns (uint256);

    function restFromTraining(uint256 _zaiId) external returns(bool);
}

interface INursery is IERC721Enumerable {
    function nextStateToMint(uint256 _tokenId) external view returns (uint256);

    function getEggsPrices(uint256 _nursId)
        external
        view
        returns (ZaiStruct.EggsPrices memory);

    function getNurseryMintedDatas(uint256 _tokenId)
        external
        view
        returns (ZaiStruct.MintedData memory);

    function getNextUnlock(uint256 _tokenId) external view returns (uint256);

    function getPreMintNumber() external view returns (uint256);

    function nurseryRevenues(uint256 _tokenId) external view returns (uint256);

    function nurseryMintedDatas(uint256 _tokenId)
        external
        view
        returns (ZaiStruct.MintedData memory);
}

interface IBZAIToken {
    function burnToken(uint256 _amount) external;
}

interface IPayments {
    function payOwner(address _owner, uint256 _value) external returns (bool);

    function getMyReward(address _user) external view returns (uint256);

    function distributeFees(uint256 _amount) external returns (bool);

    function rewardPlayer(address _user, uint256 _amount)
        external
        returns (bool);

    function getMyCentersRevenues(address _user)
        external
        view
        returns (uint256);

    function burnRevenuesForEggs(address _owner, uint256 _amount)
        external
        returns (bool);

    function payNFTOwner(address _owner, uint256 _amount)
        external
        returns (bool);

    function payRNFT(uint256 _amount) external returns (bool);

    function payWithRewardOrWallet(address _user, uint256 _amount)
        external
        returns (bool);
}

interface IEggs is IERC721Enumerable {
    function mintEgg(
        address _to,
        uint256 _state,
        uint256 _maturityDuration
    ) external returns (uint256);

    function burnEgg(uint256 _tokenId) external returns (bool);

    function isMature(uint256 _tokenId) external view returns (bool);

    function getStateIndex(uint256 _tokenId) external view returns (uint256);
}

interface IPotions is IERC721Enumerable {
    function mintPotionForSale(
        uint256 _fromLab,
        uint256 _price,
        uint256 _type,
        uint256 _power
    ) external returns (uint256);

    function offerPotion(
        uint256 _type,
        uint256 _power,
        address _to
    ) external returns (uint256);

    function updatePotion(uint256 _tokenId) external;

    function burnPotion(uint256 _tokenId) external returns (bool);

    function emptyingPotion(uint256 _tokenId) external returns(bool); 

    function mintMultiplePotion(uint256[7] memory _powers, address _owner)
        external
        returns (uint256);

    function changePotionPrice(
        uint256 _tokenId,
        uint256 _laboId,
        uint256 _price
    ) external returns (bool);

    function updatePotionSaleTimestamp(uint256 _tokenId)
        external
        returns (bool);

    function getFullPotion(uint256 _tokenId)
        external
        view
        returns (PotionStruct.Potion memory);
}

interface IAddresses {
    function getBZAIAddress() external view returns (address);

    function getOracleAddress() external view returns (address);

    function getZaiAddress() external view returns (address);

    function getZaiMetaAddress() external view returns (address);

    function getIpfsStorageAddress() external view returns (address);

    function getLaboratoryAddress() external view returns (address);

    function getLaboratoryNFTAddress() external view returns (address);

    function getTrainingCenterAddress() external view returns (address);

    function getTrainingNFTAddress() external view returns (address);

    function getNurseryAddress() external view returns (address);

    function getPotionAddress() external view returns (address);

    function getFightAddress() external view returns (address);

    function getEggsAddress() external view returns (address);

    function getMarketZaiAddress() external view returns (address);

    function getPaymentsAddress() external view returns (address);

    function getChallengeRewardsAddress() external view returns (address);

    function getWinRewardsAddress() external view returns (address);

    function getOpenAndCloseAddress() external view returns (address);

    function getAlchemyAddress() external view returns (address);

    function getWinChallengeAddress() external view returns (address);

    function isAuthToManagedNFTs(address _address) external view returns (bool);

    function isAuthToManagedPayments(address _address)
        external
        view
        returns (bool);

    function getLevelStorageAddress() external view returns (address);

    function getRankingContract() external view returns (address);

    function getAuthorizedSigner() external view returns (address);

    function getDelegateZaiAddress() external view returns (address);

    function getZaiStatsAddress() external view returns (address);

    function getLootAddress() external view returns (address);

    function getClaimNFTsAddress() external view returns (address);

    function getRentMyNftAddress() external view returns (address);

    function getChickenAddress() external view returns (address);

    function getPvPAddress() external view returns (address);

    function getRewardsPvPAddress() external view returns (address);
}

interface IOpenAndClose {
    function getLaboCreatingTime(uint256 _tokenId)
        external
        view
        returns (uint256);

    function canLaboSell(uint256 _tokenId) external view returns (bool);

    function canTrain(uint256 _tokenId) external view returns (bool);

    function laboratoryMinted() external view returns (uint256);

    function trainingCenterMinted() external view returns (uint256);

    function getLaboratoryName(uint256 _tokenId)
        external
        view
        returns (string memory);

    function getNurseryName(uint256 _tokenId)
        external
        view
        returns (string memory);

    function getTrainingCenterName(uint256 _tokenId)
        external
        view
        returns (string memory);

    function getLaboratoryState(uint256 _tokenId)
        external
        view
        returns (string memory);
}

interface IReserveForChalengeRewards {
    function updateRewards() external returns (bool);
}

interface IReserveForWinRewards {
    function updateRewards() external returns (bool);
}

interface ILevelStorage {
    function addFighter(uint256 _level, uint256 _zaiId) external returns (bool);

    function removeFighter(uint256 _level, uint256 _zaiId)
        external
        returns (bool);

    function getLevelLength(uint256 _level) external view returns (uint256);

    function getRandomZaiFromLevel(uint256 _level, uint256 _idForbiden)
        external
        returns (uint256 _zaiId);
}

interface IRewardsRankingFound {
    function getDailyRewards(address _rewardStoringAddress)
        external
        returns (uint256);

    function getWeeklyRewards(address _rewardStoringAddress)
        external
        returns (uint256);
}

interface IRewardsWinningFound {
    function getWinningRewards(uint256 level, bool bonus) external returns (uint256);
}

interface IRewardsPvP {
    function getWinningRewards() external returns (uint256);
}

interface IRanking {
    function updatePlayerRankings(address _user, uint256 _xpWin)
        external
        returns (bool);

    function getDayBegining() external view returns (uint256);

    function getDayAndWeekRankingCounter()
        external
        view
        returns (uint256 dayNumber, uint256 weekNumber);
}

interface IDelegate {
    function gotDelegationForZai(uint256 _zaiId)
        external
        view
        returns (ZaiStruct.ScholarDatas memory scholarDatas);

    function canUseZai(uint256 _zaiId, address _user)
        external
        view
        returns (bool);

    function getDelegateDatasByZai(uint256 _zaiId)
        external
        view
        returns (ZaiStruct.DelegateData memory);

    function isZaiDelegated(uint256 _zaiId) external view returns (bool);

    function updateLastScholarPlayed(uint256 _zaiId) external returns (bool);
}

interface IStats {
    function updateCounterWinLoss(
        uint256 _zaiId,
        uint256 _challengerId,
        uint256[30] memory _fightProgress,
        IRanking IRank
    ) external returns (bool);

    function getZaiStats(uint256 _zaiId)
        external
        view
        returns (uint256[4] memory);

    function updateAllPowersInGame(ZaiStruct.Powers memory toAdd)
        external
        returns (bool);


    function reduceAllPowersInGame(ZaiStruct.Powers memory toReduce)
        external
        returns (bool);
}

interface IFighting {
    function getZaiStamina(uint256 _zaiId) external view returns (uint256);

    function getDayWinByZai(uint256 zaiId) external view returns (uint256);
}

interface IFightingLibrary {
    function updateFightingProgress(
        uint256[30] memory _toReturn,
        uint256[9] memory _elements,
        uint256[9] memory _powers
    ) external pure returns (uint256[30] memory);

    function getUsedPowersByElement(
        uint256[9] memory _elements,
        uint256[9] memory _powers
    ) external pure returns (uint256[5] memory);

    function isPowersUsedCorrect(
        uint256[5] memory _got,
        uint256[5] memory _used
    ) external pure returns (bool);

    function getNewPattern(
        uint256 _random,
        ZaiStruct.Zai memory c,
        uint256[30] memory _toReturn
    ) external pure returns (uint256[30] memory result);
}

interface ILootProgress {
    function updateUserProgress(address _user) external;
}

interface IGuildeDelegation {
    function getRentingDatas(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (ZaiStruct.GuildeDatas memory);
}

interface IChicken {
    function mintChicken(address _to) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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