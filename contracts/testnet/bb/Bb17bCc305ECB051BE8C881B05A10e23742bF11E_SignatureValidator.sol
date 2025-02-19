// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Municipality.sol";

pragma solidity ^0.8.15;

contract SignatureValidator is OwnableUpgradeable, ReentrancyGuardUpgradeable, EIP712Upgradeable {

    string private constant SIGNING_DOMAIN = "SIGNATURE_VALIDATOR";
    string private constant SIGNATURE_VERSION = "1";

    address private ourSignerAddress;
    address public municipalityAddress;

    modifier onlyMunicipality() {
        require(msg.sender == municipalityAddress, "SignatureValidator: Only Municipality contract is authorized to call this function");
        _;
    }

    function initialize(
        address _ourSignerAddress
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        ourSignerAddress = _ourSignerAddress;
    }

    function setMunicipalityAddress(address _municipalityAddress) external onlyOwner {
        municipalityAddress = _municipalityAddress;
    }

    function setSignerAddress(address  _ourSignerAddress) external onlyOwner {
        ourSignerAddress = _ourSignerAddress;
    }

    function verifySigner(Municipality.ParcelsMintSignature memory mintParcelSignature) external  view onlyMunicipality returns (bool){
        require(
            mintParcelSignature.parcels.length == mintParcelSignature.signatures.length,
            "SignatureValidator: Number of signuatures does not match number of parcels"
        );
        for (uint256 index; index < mintParcelSignature.parcels.length; index++) {
            bytes32 _digest = _hash(mintParcelSignature.parcels[index]);
            address signer = ECDSAUpgradeable.recover(
                _digest,
                mintParcelSignature.signatures[index]
            );
            if(signer != ourSignerAddress) {
                return false;
            }
        }
        return true;
    }

    function _hash(Municipality.Parcel memory parcel) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Parcel(uint16 x,uint16 y,uint8 parcelLandType)"
                        ),
                        parcel
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/ISignatureValidator.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IParcelInterface.sol";
import "./interfaces/IERC721Base.sol";
import "./interfaces/IMinerNFT.sol";
import "./interfaces/IMining.sol";

contract Municipality is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Parcel {
        uint16 x;
        uint16 y;
        uint8 parcelLandType;
    }

    // Used to keep Parcel information
    struct ParcelInfo {
        bool isUpgraded;
        uint8 parcelType;
        uint8 parcelLandType;
        bool isValid;
    }

    struct SuperBundleInfo {
        uint256 parcelsAmount;
        uint256 minersAmount;
        uint256 upgradesAmount;
        uint256 discountPct;
    }

    struct ParcelsMintSignature {
        Parcel[] parcels;
        bytes[] signatures;
    }

    struct UserMintableNFTAmounts {
        uint256 parcels;
        uint256 miners;
        uint256 upgrades;
    }

    struct LastPurchaseData {
        uint256 lastPurchaseDate;
        uint256 expirationDate;
        uint256 dollarValue;
    }

    uint8 private constant PARCEL_TYPE_STANDARD = 10;

    uint8 private constant PARCEL_LAND_TYPE_NEXT_TO_OCEAN = 10;
    uint8 private constant PARCEL_LAND_TYPE_NEAR_OCEAN = 20;
    uint8 private constant PARCEL_LAND_TYPE_INLAND = 30;

    uint8 private constant BUNDLE_TYPE_SUPER_1 = 1;
    uint8 private constant BUNDLE_TYPE_SUPER_2 = 2;
    uint8 private constant BUNDLE_TYPE_SUPER_3 = 3;
    uint8 private constant BUNDLE_TYPE_SUPER_4 = 4;

    uint8 private constant PURCHASE_TYPE_BUSD = 10;
    uint8 private constant PURCHASE_TYPE_BUSD_METAVIE = 20;

    mapping(address => UserMintableNFTAmounts) public usersMintableNFTAmounts;
    mapping(address => uint256) public userToPurchasedAmountMapping;
    mapping(address => LastPurchaseData) public lastPurchaseData;
    mapping(uint256 => uint256[]) public parcelToMinersMapping;
    mapping(uint256 => uint256) public minerToParcelMapping;

    /// @notice Pricing information (in BUSD)
    uint256 public parcelUpgradePrice;
    uint256 public minerUpgradePrice;
    uint256 public minerPrice;

	/// @notice Parcels pricing changes per percentage
    uint256 public currentlySoldStandardParcelsCount;

    /// @notice Addresses of Kabutocho smart contracts
    address public amountsDistributorAddress;
    address public signatureValidatorAddress;
    address public standardParcelNFTAddress;
    address public minerV1NFTAddress;
    address public metavieAddress;
    address public miningAddress;
    address public routerAddress;
    address public wbnbAddress;
    address public busdAddress;

    /// @notice Parcel <=> Miner attachments and Parcel/Miner properties
    uint8 public standardParcelSlotsCount;
    uint8 public upgradedParcelSlotsCount;

    /// @notice Indicator if the sales can happen
    bool public isSaleActive;

    SuperBundleInfo[4] public superBundlesInfos;
    
    // ------------------------------------ EVENTS ------------------------------------ //

    event SuperBundlesSet(SuperBundleInfo[4] indexed bundles);
    event ParcelsSlotsCountSet(
        uint8 indexed standardParcelSlotsCount,
        uint8 indexed upgradedParcelSlotsCount
    );
    event PurchasePricesSet(
        uint256 parcelUpgradePrice,
        uint256 minerUpgradePrice,
        uint256 minerPrice
    );
    event SaleActivationSet(bool indexed saleActivation);
    event BundlePurchased(address indexed user, uint256 indexed bundleType);
    event SuperBundlePurchased(address indexed user, uint256 indexed bundleType);
    event StandardParcelUpgraded(address indexed user, uint256 indexed parcelId);
    event MinerUpgraded(address indexed user, uint256 indexed minerId, uint256 indexed level);
    event MinersUpgraded(address indexed user, uint256[] indexed minersIds, uint256[] indexed levels);
    event NFTContractAddressesSet(address[9] indexed _nftContractAddresses);
    event MinerAttached(uint256 indexed parcelId, uint256 indexed minerId);
    event MinerDetached(uint256 indexed parcelId, uint256 indexed minerId);
    event MinersUpdated(uint256 indexed parcelId, uint256[] indexed minersId);

    /// @notice Modifier for 0 address check
    modifier notZeroAddress() {
        require(address(0) != msg.sender, "Municipality: Caller can not be address 0");
        _;
    }

    /// @notice Modifier not to allow sales when it is made inactive
    modifier onlySaleActive() {
        require(isSaleActive, "Municipality: Sale is deactivated now");
        _;
    }

    // @notice Proxy SC support - initialize internal state
    function initialize(
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    receive() external payable {}

    fallback() external payable {}

    /// @notice Public interface

    /// @notice Set Super Bundles
    function setSuperBundles(SuperBundleInfo[4] calldata _bundles) external onlyOwner notZeroAddress {
        superBundlesInfos = _bundles;
        emit SuperBundlesSet(_bundles);
    }

    /// @notice Set contract addresses for all NFTs we currently have
    function setNFTContractAddresses(address[9] calldata _nftContractAddresses) external onlyOwner {
        standardParcelNFTAddress = _nftContractAddresses[0];
        minerV1NFTAddress = _nftContractAddresses[1];
        miningAddress = _nftContractAddresses[2];
        wbnbAddress = _nftContractAddresses[3];
        busdAddress = _nftContractAddresses[4];
        metavieAddress = _nftContractAddresses[5];
        signatureValidatorAddress = _nftContractAddresses[6];
        routerAddress = _nftContractAddresses[7];
        amountsDistributorAddress = _nftContractAddresses[8];
        emit NFTContractAddressesSet(_nftContractAddresses);
    }
    
    /// @notice Set the number of slots available for the miners for standard and upgraded parcels
    function setParcelsSlotsCount(uint8[2] calldata _parcelsSlotsCount) external onlyOwner {
        standardParcelSlotsCount = _parcelsSlotsCount[0];
        upgradedParcelSlotsCount = _parcelsSlotsCount[1];

        emit ParcelsSlotsCountSet(_parcelsSlotsCount[0], _parcelsSlotsCount[1]);
    }

    /// @notice Set the prices for all different entities we currently sell
    function setPurchasePrices(uint256[3] calldata _purchasePrices) external onlyOwner {
        parcelUpgradePrice = _purchasePrices[0];
        minerUpgradePrice = _purchasePrices[1];
        minerPrice = _purchasePrices[2];

        emit PurchasePricesSet(
            _purchasePrices[0],
            _purchasePrices[1],
            _purchasePrices[2]
        );
    }

    /// @notice Activate/Deactivate sales
    function setSaleActivation(bool _saleActivation) external onlyOwner {
        isSaleActive = _saleActivation;
        emit SaleActivationSet(_saleActivation);
    }

    // @notice (Purchase) Generic minting functionality for parcels, regardless the currency
    function mintParcels(ParcelsMintSignature memory _mintingSignature, uint8 _purchaseType)
        external
        onlySaleActive
        notZeroAddress
    {
        require(ISignatureValidator(signatureValidatorAddress).verifySigner(_mintingSignature), "Municipality: Not authorized signer");
        uint256 parcelsLength = _mintingSignature.parcels.length;
        require(parcelsLength > 0, "Municipality: Can not mint 0 parcels");
        uint256[2] memory busdAndMetavie = _getUserPriceForParcels(msg.sender, parcelsLength, _purchaseType);
        if(busdAndMetavie[0] > 0) {
            if(busdAndMetavie[1] > 0) 
                _transferToContract(busdAndMetavie[1], metavieAddress);
            _transferToContract(busdAndMetavie[0], busdAddress);
            userToPurchasedAmountMapping[msg.sender] += busdAndMetavie[0] + busdAndMetavie[1];
            lastPurchaseData[msg.sender].dollarValue += busdAndMetavie[0] + busdAndMetavie[1];

            _lastPurchaseDateUpdate(msg.sender);
            usersMintableNFTAmounts[msg.sender].parcels = 0;
        } else 
            usersMintableNFTAmounts[msg.sender].parcels -= parcelsLength;
        IParcelInterface(standardParcelNFTAddress).mintParcels(msg.sender, _mintingSignature.parcels);
        currentlySoldStandardParcelsCount += parcelsLength;
    }

    // @notice (Purchase) Mint the given amount of miners
    function mintMiners(uint256 _count, uint8 _purchaseType) external onlySaleActive notZeroAddress returns(uint256, uint256)
    {
        require(_count > 0, "Municipality: Can not mint 0 miners");
        uint256[2] memory busdAndMetavie = _getUserPriceForMiners(msg.sender, _count, _purchaseType);
        if(busdAndMetavie[0] > 0) {
            if(busdAndMetavie[1] > 0) 
                _transferToContract(busdAndMetavie[1], metavieAddress);
            _transferToContract(busdAndMetavie[0], busdAddress);
            userToPurchasedAmountMapping[msg.sender] += busdAndMetavie[0] + busdAndMetavie[1];
            lastPurchaseData[msg.sender].dollarValue += busdAndMetavie[0] + busdAndMetavie[1];
            _lastPurchaseDateUpdate(msg.sender);
            usersMintableNFTAmounts[msg.sender].miners = 0;
        } else {
            usersMintableNFTAmounts[msg.sender].miners -= _count;
        }
        return IMinerNFT(minerV1NFTAddress).mintMiners(msg.sender, _count);
    }
    function purchaseSuperBundle(uint8 _bundleType, uint8 _purchaseType) external onlySaleActive notZeroAddress
    {
        _validateSuperBundleType(_bundleType);
        SuperBundleInfo memory bundle = superBundlesInfos[_bundleType - BUNDLE_TYPE_SUPER_1];
        LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
        uint256[2] memory busdAndMetavie = _getPriceForSuperBundle(_bundleType,_purchaseType);
        if(busdAndMetavie[1] > 0) 
            _transferToContract(busdAndMetavie[1], metavieAddress);
        _transferToContract(busdAndMetavie[0], busdAddress);
        userToPurchasedAmountMapping[msg.sender] += busdAndMetavie[0] + busdAndMetavie[1];
        lastPurchase.dollarValue += busdAndMetavie[0] + busdAndMetavie[1];
        _lastPurchaseDateUpdate(msg.sender);
        usersMintableNFTAmounts[msg.sender].parcels += bundle.parcelsAmount;
        usersMintableNFTAmounts[msg.sender].upgrades += bundle.upgradesAmount;
        usersMintableNFTAmounts[msg.sender].miners += bundle.minersAmount;
        emit SuperBundlePurchased(msg.sender, _bundleType);
    }

    // granting free Parcels to selected user 
    function grantParcels(ParcelsMintSignature calldata _mintingSignature,
     address _user) external onlyOwner {
        require(_mintingSignature.parcels.length <= 240, "Municipality: The amount of miners should be less or equal to 240");
        require(ISignatureValidator(signatureValidatorAddress).verifySigner(_mintingSignature), "Municipality: Not authorized signer");
        IParcelInterface(standardParcelNFTAddress).mintParcels(_user, _mintingSignature.parcels);
        currentlySoldStandardParcelsCount += _mintingSignature.parcels.length;
    }

    // granting free Miners to selected user
    function grantMiners(uint8 _minersAmount, address _user) external onlyOwner returns(uint256, uint256) {
        require(_minersAmount <= 240, "Municipality: The amount of miners should be less than or equal to 240");
        (uint256 firstMinerId, uint256 count) = IMinerNFT(minerV1NFTAddress).mintMiners(_user, _minersAmount);
        return (firstMinerId, count);
    }

    /// @notice Upgrade a group of standard parcels
    function upgradeStandardParcelsGroup(uint256[] memory _parcelIds, uint8 _purchaseType) external onlySaleActive {
        uint256 totalUpgradePrice = _parcelIds.length * parcelUpgradePrice;
        for(uint256 i = 0; i < _parcelIds.length; ++i) {
            require(
                IERC721Base(standardParcelNFTAddress).ownerOf(_parcelIds[i]) == msg.sender,
                "Municipality: Invalid NFT owner"
            );
            require(!IParcelInterface(standardParcelNFTAddress).isParcelUpgraded(_parcelIds[i]),
                "Municipality: Parcel is already upgraded");
            if(usersMintableNFTAmounts[msg.sender].upgrades > 0) {
                usersMintableNFTAmounts[msg.sender].upgrades--;
                totalUpgradePrice -= parcelUpgradePrice;
            }
        }
        if(totalUpgradePrice > 0) {
            uint256 busdAmount = totalUpgradePrice;
            uint256 metavieAmount;
            if(_purchaseType == PURCHASE_TYPE_BUSD_METAVIE) {
                metavieAmount = busdAmount * _getMetaviePriceInBUSD() / 10 ether;
                busdAmount -= busdAmount / 10;
                _transferToContract(metavieAmount, metavieAddress);
            }
            _transferToContract(totalUpgradePrice, busdAddress);
            LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
            userToPurchasedAmountMapping[msg.sender] += totalUpgradePrice;
            lastPurchase.dollarValue += totalUpgradePrice;
            _lastPurchaseDateUpdate(msg.sender);
        }
        IParcelInterface(standardParcelNFTAddress).upgradeParcels(_parcelIds);
    }

    /// @notice Upgrade the standard parcel
    function upgradeStandardParcel(uint256 _parcelId, uint8 _purchaseType) external onlySaleActive {
        require(
            IERC721Base(standardParcelNFTAddress).ownerOf(_parcelId) == msg.sender,
            "Municipality: Invalid NFT owner"
        );
        bool isParcelUpgraded = IParcelInterface(standardParcelNFTAddress).isParcelUpgraded(_parcelId);
        require(!isParcelUpgraded, "Municipality: Parcel is already upgraded");
        uint256 amount = parcelUpgradePrice;
        if(_purchaseType == PURCHASE_TYPE_BUSD_METAVIE) {
            uint256 metavieAmountBUSD = amount / 10;
            amount = amount * 9 / 10;
            address[] memory path = new address[](2);

            path[0] = busdAddress;
            path[1] = metavieAddress;

            uint metavieAmount = IPancakeRouter02(routerAddress).getAmountsOut(metavieAmountBUSD, path)[1];
            _transferToContract(metavieAmount, metavieAddress);
        }
        _transferToContract(amount, busdAddress);
        LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
        userToPurchasedAmountMapping[msg.sender] += amount;
        lastPurchase.dollarValue += amount;
        _lastPurchaseDateUpdate(msg.sender);
        IParcelInterface(standardParcelNFTAddress).upgradeParcel(_parcelId);
        emit StandardParcelUpgraded(msg.sender, _parcelId);
    }

    function upgradeMiner(uint256 _minerId, uint8 _purchaseType) external onlySaleActive {
        require(
            IERC721Base(minerV1NFTAddress).ownerOf(_minerId) == msg.sender,
            "Municipality: Invalid NFT owner"
        );
        uint256 minerCurrentLevel = IMinerNFT(minerV1NFTAddress).minerIdToLevelMapping(_minerId);
        require(minerCurrentLevel <= 9,"Municipality: Miner level maxed");
        uint256 amount = minerUpgradePrice;
        if(_purchaseType == PURCHASE_TYPE_BUSD_METAVIE) {
            uint256 metavieAmountBUSD = amount / 10;
            amount = amount * 9 / 10;
            address[] memory path = new address[](2);

            path[0] = busdAddress;
            path[1] = metavieAddress;

            uint metavieAmount = IPancakeRouter02(routerAddress).getAmountsOut(metavieAmountBUSD, path)[1];
            _transferToContract(metavieAmount, metavieAddress);
        }
        _transferToContract(amount, busdAddress);
        LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
        userToPurchasedAmountMapping[msg.sender] += amount;
        lastPurchase.dollarValue += amount;
        _lastPurchaseDateUpdate(msg.sender);
        IMinerNFT(minerV1NFTAddress).upgradeMinerLevels(_minerId, 1);
        if(minerToParcelMapping[_minerId] != 0)
            IMining(miningAddress).increaseHashrate(msg.sender, 1000);
        emit MinerUpgraded(msg.sender, _minerId, IMinerNFT(minerV1NFTAddress).minerIdToLevelMapping(_minerId));
    }

    function upgradeAllMiners(uint8 _purchaseType) external onlySaleActive {
        uint256 amount = _getPriceForUpgradingAllMiners(msg.sender);
        uint256[] memory miners = IERC721Base(minerV1NFTAddress).tokensOf(msg.sender);
        if(_purchaseType == PURCHASE_TYPE_BUSD_METAVIE) {
            uint256 metavieAmountBUSD = amount / 10;
            amount = amount * 9 / 10;
            address[] memory path = new address[](2);

            path[0] = busdAddress;
            path[1] = metavieAddress;

            uint metavieAmount = IPancakeRouter02(routerAddress).getAmountsOut(metavieAmountBUSD, path)[1];
            _transferToContract(metavieAmount, metavieAddress);
        }
        _transferToContract(amount, busdAddress);
        LastPurchaseData storage lastPurchase = lastPurchaseData[msg.sender];
        userToPurchasedAmountMapping[msg.sender] += amount;
        lastPurchase.dollarValue += amount;
        _lastPurchaseDateUpdate(msg.sender);
        uint256[] memory upgradedMiners;
        uint256[] memory levels;
        uint256 additionalHashrate;
        for(uint i; i < miners.length; i++){
            uint256 minerLevel = IMinerNFT(minerV1NFTAddress).minerIdToLevelMapping(miners[i]);
            if(minerLevel < 9){
                IMinerNFT(minerV1NFTAddress).upgradeMinerLevels(miners[i], 1);
                upgradedMiners[upgradedMiners.length] = miners[i];
                levels[levels.length] = minerLevel+1;
                if(minerToParcelMapping[miners[i]] != 0)
                    additionalHashrate += 1000;
            }
        }
        IMining(miningAddress).increaseHashrate(msg.sender, additionalHashrate);
        emit MinersUpgraded(msg.sender, upgradedMiners, levels);
    }

    function attachMinerToParcel(uint256 _parcelId, uint256 _minerId) external {
        require(msg.sender == IERC721Base(standardParcelNFTAddress).ownerOf(_parcelId),"Municipality: You are not authorized for this action");
        require(msg.sender == IERC721Base(minerV1NFTAddress).ownerOf(_minerId), "Municipality: You are not authorized for this actrion");
        uint256 parcelSlots = IParcelInterface(standardParcelNFTAddress).upgradedParcelsMapping(_parcelId) ? upgradedParcelSlotsCount: standardParcelSlotsCount;
        require(parcelToMinersMapping[_parcelId].length < parcelSlots, "Municipality: Parcel does not have available slots");
        require(minerToParcelMapping[_minerId] == 0,"Municipality: Miner is already atached");
        parcelToMinersMapping[_parcelId].push(_minerId);
        minerToParcelMapping[_minerId] = _parcelId;
        IMining(miningAddress).increaseHashrate(msg.sender, IMinerNFT(minerV1NFTAddress).hashrate(_minerId));
        emit MinerAttached(_parcelId,_minerId);
    }

    function detachMinerFromParcel(uint256 _parcelId, uint256 _minerId) external {
        require(msg.sender == IERC721Base(standardParcelNFTAddress).ownerOf(_parcelId),"Municipality: You are not authorized for this action");
        require(minerToParcelMapping[_minerId] == _parcelId,"Municipality: Miner is not attached to this parcel");
        for(uint i; i < parcelToMinersMapping[_parcelId].length; i++) {
            if(parcelToMinersMapping[_parcelId][i] == _minerId) {
                parcelToMinersMapping[_parcelId][i] = parcelToMinersMapping[_parcelId][parcelToMinersMapping[_parcelId].length];
                parcelToMinersMapping[_parcelId].pop();
                minerToParcelMapping[parcelToMinersMapping[_parcelId][i]] = 0;
                IMining(miningAddress).decreaseHashrate(msg.sender, IMining(miningAddress).userHashrate(msg.sender) - IMinerNFT(minerV1NFTAddress).hashrate(_minerId));
                return;
            }
        }
        emit MinerDetached(_parcelId,_minerId);
    }

    function updateMinesrOnParcel(uint256 _parcelId, uint256[] memory _newMiners) external {
        require(msg.sender == IERC721Base(standardParcelNFTAddress).ownerOf(_parcelId),"Municipality: You are not authorized for this action");
        uint256 parcelSlots = IParcelInterface(standardParcelNFTAddress).upgradedParcelsMapping(_parcelId) ? upgradedParcelSlotsCount: standardParcelSlotsCount;
        require(_newMiners.length <= parcelSlots, "Municipality: Parcel does not have available slots");
        uint256[] storage _oldMiners =  parcelToMinersMapping[_parcelId];
        uint256 currentHashrate = IMining(miningAddress).userHashrate(msg.sender); 
        uint256 newHashrate = currentHashrate;
        for(uint i; i < _oldMiners.length; i++) {
            if(!_arrayContains(_newMiners, _oldMiners[i])) {
                _oldMiners[i] = _oldMiners[_oldMiners.length];
                _oldMiners.pop();
                minerToParcelMapping[_oldMiners[i]] = 0;
                newHashrate -= IMinerNFT(minerV1NFTAddress).hashrate(_oldMiners[i]);
            }
        }
        for(uint i; i < _newMiners.length; i++) {
            if(minerToParcelMapping[_newMiners[i]] != _parcelId){
                require(msg.sender == IERC721Base(minerV1NFTAddress).ownerOf(_newMiners[i]), "Municipality: You are not authorized for this actrion");
                parcelToMinersMapping[_parcelId].push(_newMiners[i]);
                minerToParcelMapping[_newMiners[i]] = _parcelId;
                newHashrate -= IMinerNFT(minerV1NFTAddress).hashrate(_oldMiners[i]);
            }
        }
        if(currentHashrate < newHashrate) 
            IMining(miningAddress).increaseHashrate(msg.sender, newHashrate - currentHashrate);
        else if(newHashrate < currentHashrate) 
            IMining(miningAddress).decreaseHashrate(msg.sender, currentHashrate - newHashrate);
        emit MinersUpdated(_parcelId, _newMiners);
    }

    function updateAttachedMiners(uint256[] memory _minersToAttach, uint256[] memory _minersToDetach) external {
        uint256 currentHashrate = IMining(miningAddress).userHashrate(msg.sender);
        uint256 hashrate = currentHashrate;
        for(uint i; i < _minersToDetach.length; i++) {
            require(msg.sender == IERC721Base(minerV1NFTAddress).ownerOf(_minersToDetach[i]),"Municipality: You can not detach this miner");
            uint256 parcel = minerToParcelMapping[_minersToDetach[i]];
            for(uint j; j < parcelToMinersMapping[parcel].length; j++) {
                if(parcelToMinersMapping[parcel][j] == _minersToDetach[i]) {
                    parcelToMinersMapping[parcel][j] = parcelToMinersMapping[parcel][parcelToMinersMapping[parcel].length];
                    parcelToMinersMapping[parcel].pop();
                    minerToParcelMapping[_minersToDetach[i]] = 0;
                    hashrate -= IMinerNFT(minerV1NFTAddress).hashrate(_minersToDetach[i]);
                }
            }
        }
        uint256[] memory parcels = IERC721Base(standardParcelNFTAddress).tokensOf(msg.sender);
        uint256 minerId;
        for(uint i; i < parcels.length; i++) {
            uint256 slots = IParcelInterface(standardParcelNFTAddress).upgradedParcelsMapping(parcels[i]) ? upgradedParcelSlotsCount: standardParcelSlotsCount;
            while(parcelToMinersMapping[parcels[i]].length < slots) {
                require(msg.sender == IERC721Base(minerV1NFTAddress).ownerOf(_minersToAttach[minerId]));
                parcelToMinersMapping[parcels[i]][parcelToMinersMapping[parcels[i]].length] = _minersToAttach[minerId];
                minerToParcelMapping[_minersToAttach[minerId]] = parcels[i];
                hashrate += IMinerNFT(minerV1NFTAddress).hashrate(_minersToAttach[minerId]);
                minerId++;       
            }         
        }
        require(minerId+1 == _minersToAttach.length,"Municipality: Not enough slots");
    } 

    function getPriceForSuperBundle(uint8 _bundleType, uint8 _purchaseType) external view returns(uint256[2] memory) {
        return _getPriceForSuperBundle(_bundleType, _purchaseType);
    }
    function getUserPriceForParcels(address _user, uint256 _parcelsCount, uint8 _purchaseType) external view returns(uint256[2] memory) {
        return(_getUserPriceForParcels(_user, _parcelsCount, _purchaseType));
    }
    function getUserPriceForMiners(address _user, uint256 _minersCount, uint8 _purchaseType) external view returns(uint256[2] memory) {
        return(_getUserPriceForMiners(_user, _minersCount, _purchaseType));
    }


    // @notice App will use this function to get the price for the selected parcels
    function getPriceForParcels(Parcel[] calldata parcels) external view returns (uint256, uint256) {
        (uint256 price, uint256 unitPrice) = _getPriceForParcels(parcels.length);
        return (price, unitPrice);
    }
    
    function getUserMiners(address _user) external view returns (uint256[] memory) {
        return IERC721Base(minerV1NFTAddress).tokensOf(_user);
    }

    function getMetaviePriceInBUSD() external view returns (uint256) {
        return _getMetaviePriceInBUSD();
    }
    function getUserMinersCountUnderLevel(address _user, uint256 _level) external view returns (uint256) {
        return _getUserMinersCountUnderLevel(_user, _level);
    }

    function getTopMiners(address _user, uint256 _count) external view returns(uint256[] memory) {
        return _getTopMiners(_user, _count);
    }

    function getMinersToDetach(address _user) external view returns(uint256[] memory) {
        uint256 userSlots = _getUserSlots(_user);
        uint256[] memory newMiners = _getTopMiners(_user, userSlots);
        uint256[] memory miners = IERC721Base(minerV1NFTAddress).tokensOf(msg.sender);
        uint256[] memory minersToDetach;
        for(uint256 i; i < miners.length; i++) {
            if(minerToParcelMapping[miners[i]] != 0 && !_arrayContains(newMiners, miners[i]))
                minersToDetach[minersToDetach.length] = miners[i];
        }
        return minersToDetach;
    }

    function getMinersToAtach(address _user) external view returns(uint256[] memory) {
        uint256 userSlots = _getUserSlots(_user);
        uint256[] memory newMiners = _getTopMiners(_user, userSlots);
        uint256[] memory minersToAtach;
        for(uint256 i; i < newMiners.length; i++) {
            if(minerToParcelMapping[newMiners[i]] == 0)
                minersToAtach[minersToAtach.length] = newMiners[i];
        }
        return minersToAtach;
    }

    function _getUserMinersCountUnderLevel(address _user, uint256 _level) private view returns (uint256) {
        uint256 totalMiners;
        uint256[] memory userMiners = IERC721Base(minerV1NFTAddress).tokensOf(_user); 
        for(uint i; i <= userMiners.length; i++){
            if(IMinerNFT(minerV1NFTAddress).minerIdToLevelMapping(userMiners[i]) < _level - 1)
                totalMiners += 1;
        }
        return totalMiners;
    }
    function _getTopMiners(address _user, uint256 _count) private view returns(uint256[] memory) {
        uint256[] memory topMiners;
        uint256[] memory userMiners = IERC721Base(minerV1NFTAddress).tokensOf(_user);
        require(_count <= userMiners.length, "Municipality: Not enough miners");
        if(userMiners.length == 0)
            return topMiners;
        topMiners[0] = userMiners[0];
        uint256 minersCount = 1;
        for(uint i; i < userMiners.length; i++) {
            uint256 minerLevel = IMinerNFT(minerV1NFTAddress).minerIdToLevelMapping(userMiners[i]);  
            if(minerLevel <= IMinerNFT(minerV1NFTAddress).minerIdToLevelMapping(topMiners[minersCount - 1])) {
                if(minersCount != _count) {
                    topMiners[minersCount] = userMiners[i];
                    minersCount++;
                }
            } else {
                uint256 current = minersCount - 1;
                if(minersCount == _count) {
                    topMiners[minersCount - 1] = topMiners[minersCount - 2];
                    current--;
                }
                while(IMinerNFT(minerV1NFTAddress).minerIdToLevelMapping(topMiners[current - 1]) > minerLevel && current != 0) {
                    topMiners[current] = topMiners[current - 1];
                    current--;
                }
                topMiners[current] = userMiners[i];
            }
        }
        return topMiners;
    }

    function _getUserSlots(address _user) private view returns(uint256) {
        uint256[] memory parcels = IERC721Base(standardParcelNFTAddress).tokensOf(_user);
        uint256 totalSlots;
        for(uint i; i < parcels.length; i++) {
            totalSlots += IParcelInterface(standardParcelNFTAddress).upgradedParcelsMapping(parcels[i]) ? upgradedParcelSlotsCount: standardParcelSlotsCount;
        }
        return totalSlots;
    }

    function _getPriceForSuperBundle(uint8 _bundleType, uint8 _purchaseType) private view returns(uint256[2] memory) {
        _validateSuperBundleType(_bundleType);
        SuperBundleInfo memory bundle = superBundlesInfos[_bundleType- BUNDLE_TYPE_SUPER_1];
        (uint256 parcelPrice, ) = _getPriceForParcels(bundle.parcelsAmount);
        uint256 bundlePrice = parcelPrice + bundle.minersAmount * minerPrice;
        uint256 discountedPrice = _discountPrice(bundlePrice, bundle.discountPct);
        uint256[2] memory busdAndMetavie = [discountedPrice, 0];
        if(_purchaseType == PURCHASE_TYPE_BUSD_METAVIE) {
            busdAndMetavie[0] = discountedPrice * 9 / 10;
            busdAndMetavie[1] = discountedPrice / 10 * _getMetaviePriceInBUSD();
        }
        return busdAndMetavie;
    }
    function _getUserPriceForParcels(address _user, uint256 _parcelsCount, uint8 _purchaseType) private view returns(uint256[2] memory) {
        if(usersMintableNFTAmounts[_user].parcels >= _parcelsCount)
            return [uint256(0),uint256(0)];
        else {
            uint256 unpaidCount = _parcelsCount - usersMintableNFTAmounts[_user].parcels;
            (uint256 price,) = _getPriceForParcels(unpaidCount);
            uint256 percentage;
            if(unpaidCount >= 90) {
                percentage = 35187;
            } else if(unpaidCount >= 35) {
                percentage = 28577;
            } else if(unpaidCount >= 16) {
                percentage = 21875;
            } else if(unpaidCount >= 3) {
                percentage = 16667;
            }
            uint256 discountedPrice = _discountPrice(price, percentage);
            uint256[2] memory busdAndMetavie = [discountedPrice, 0];
            if(_purchaseType == PURCHASE_TYPE_BUSD_METAVIE) {
                busdAndMetavie[0] = discountedPrice * 9 / 10;
	            busdAndMetavie[1] = discountedPrice * _getMetaviePriceInBUSD() / 10 ether;            
            }
            return busdAndMetavie;
        }
    }
    function _getUserPriceForMiners(address _user, uint256 _minersCount, uint8 _purchaseType) private view returns(uint256[2] memory) {
        if(usersMintableNFTAmounts[_user].miners >= _minersCount)
            return [uint256(0),uint256(0)];
        else {
            uint256 unpaidCount = _minersCount - usersMintableNFTAmounts[_user].miners;
            uint256 price = unpaidCount * minerPrice;
            uint256 percentage;
            if(unpaidCount >= 360) {
                percentage = 35187;
            } else if(unpaidCount >= 140) {
                percentage = 28577;
            } else if(unpaidCount >= 64) {
                percentage = 21875;
            } else if(unpaidCount >= 12) {
                percentage = 16667;
            }
            uint256 discountedPrice = _discountPrice(price, percentage);
            uint256[2] memory busdAndMetavie = [discountedPrice, 0];
            if(_purchaseType == PURCHASE_TYPE_BUSD_METAVIE) {
                busdAndMetavie[0] = discountedPrice * 9 / 10;
	            busdAndMetavie[1] = discountedPrice * _getMetaviePriceInBUSD() / 10 ether;            
            }
            return busdAndMetavie;
        }
    }

    function _getPriceForUpgradingAllMiners(address _user) private view returns(uint256){
        return (IMinerNFT(minerV1NFTAddress).balanceOf(_user) - _getUserMinersCountUnderLevel(_user,10)) * minerUpgradePrice;
    }


    // @notice Private interface
    function _arrayContains(uint256[] memory _miners, uint256 _miner) private pure returns(bool) {
        for(uint i; i < _miners.length; i++) {
            if(_miners[i] == _miner)
                return true;
        }
        return false;
    }

    /// @notice Transfers the given BUSD amount to distributor contract
    function _transferToContract(uint256 _amount, address _token) private {
        IERC20Upgradeable(_token).safeTransferFrom(
            address(msg.sender),
            address(amountsDistributorAddress),
            _amount
        );
    }

    function _validateSuperBundleType(uint8 _bundleType) private pure {
        require
        (
            _bundleType == BUNDLE_TYPE_SUPER_1 ||
            _bundleType == BUNDLE_TYPE_SUPER_2 ||
            _bundleType == BUNDLE_TYPE_SUPER_3 ||
            _bundleType == BUNDLE_TYPE_SUPER_4,
            "Municipality: Invalid super bundle type"
        );
    }

    /// @notice Returns the price of a given parcels
    function _getPriceForParcels(uint256 parcelsCount) private view returns (uint256, uint256) {
        uint256 price = parcelsCount * 100000000000000000000;
        uint256 unitPrice = 100000000000000000000;
        uint256 priceBefore = 0;
        uint256 totalParcelsToBuy = currentlySoldStandardParcelsCount + parcelsCount;
        if(totalParcelsToBuy > 157500) {
            unitPrice = 301000000000000000000;
            if (currentlySoldStandardParcelsCount > 157500) {
                price = parcelsCount * 301000000000000000000;
            } else {
                price = (parcelsCount + currentlySoldStandardParcelsCount - 157500) * 301000000000000000000;
                priceBefore = (157500 - currentlySoldStandardParcelsCount) * 209000000000000000000;
            }
        } else if(totalParcelsToBuy > 105000) {
            unitPrice = 209000000000000000000;
             if (currentlySoldStandardParcelsCount > 105000) {
                price = parcelsCount * 209000000000000000000;
            } else {
                price = (parcelsCount + currentlySoldStandardParcelsCount - 105000) * 209000000000000000000;
                priceBefore = (105000 - currentlySoldStandardParcelsCount) * 144000000000000000000;
            }
        } else if(totalParcelsToBuy > 52500) {
            unitPrice = 144000000000000000000;
            if (currentlySoldStandardParcelsCount > 52500) {
                price = parcelsCount * 144000000000000000000;
            } else {
                price = (parcelsCount + currentlySoldStandardParcelsCount - 52500) * 144000000000000000000;
                priceBefore = (52500 - currentlySoldStandardParcelsCount) * 116000000000000000000;
            }
        } else if(totalParcelsToBuy > 21000) {
             unitPrice = 116000000000000000000;
            if (currentlySoldStandardParcelsCount > 21000) {
                price = parcelsCount * 116000000000000000000; 
            } else {
                price = (parcelsCount + currentlySoldStandardParcelsCount - 21000) * 116000000000000000000;
                priceBefore = (21000 - currentlySoldStandardParcelsCount) * 100000000000000000000;
            }
            
        }
        return (priceBefore + price, unitPrice);
    }


    /// @notice Returns the discounted price of the bundle
    function _discountPrice(uint256 _price, uint256 _percentage) private pure returns (uint256) {
        return _price - (_price * _percentage) / 100000;
    }

    /**
     * @notice Private function to update last purchase date
     * @param _user: user address
     */
    function _lastPurchaseDateUpdate(address _user) private {
        LastPurchaseData storage lastPurchase = lastPurchaseData[_user];
        lastPurchase.lastPurchaseDate = block.timestamp;
        uint256 _lastDate = _checkPurchaseDate(_user);
        if (lastPurchase.expirationDate < _lastDate + 30 days) {
            lastPurchase.expirationDate = _lastDate + 30 days;
        }
        if(lastPurchase.expirationDate < block.timestamp) {
            lastPurchase.expirationDate = lastPurchase.lastPurchaseDate;
        }
        if (lastPurchase.dollarValue >= (100 * 1e18)) {
            lastPurchase.expirationDate = lastPurchase.lastPurchaseDate + 30 days;
            lastPurchase.dollarValue = 0;     
        }
    }

    function _checkPurchaseDate(address _user) private view returns (uint256) {
        uint256 _lastDate = IERC721Base(standardParcelNFTAddress).getUserPurchaseTime(_user)[0];
        if (IERC721Base(minerV1NFTAddress).getUserPurchaseTime(_user)[0] >  _lastDate) {
            _lastDate = IERC721Base(minerV1NFTAddress).getUserPurchaseTime(_user)[0];
        }
        return _lastDate;

    }

    function _getMetaviePriceInBUSD() private view returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = metavieAddress;
        path[1] = wbnbAddress;
        uint256[] memory metaviePriceInWBNB = IPancakeRouter02(routerAddress).getAmountsOut(
            1000000000000000000,
            path
        );
        path[0] = wbnbAddress;
        path[1] = busdAddress;
        uint256[] memory wbnbPriceInBUSD = IPancakeRouter02(routerAddress).getAmountsOut(
            1,
            path
        );
        return metaviePriceInWBNB[1] * wbnbPriceInBUSD[1];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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

pragma solidity ^0.8.15;

import "../Municipality.sol";

interface ISignatureValidator {
    function verifySigner(Municipality.ParcelsMintSignature memory mintParcelSignature) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Municipality.sol";

interface IParcelInterface {
    function mint(address user, uint256 x, uint256 y, uint256 landType) external returns (uint256);
    function parcelExists(uint256 x, uint256 y, uint256 landType) external view returns(bool);
    function getParcelId(uint256 x, uint256 y, uint256 landType) external pure returns (uint256);
    function isParcelUpgraded(uint256 tokenId) external view returns (bool);
    function upgradeParcel(uint256 tokenId) external;
    function mintParcels(address _user, Municipality.Parcel[] calldata parcels) external returns(uint256[] memory);
    function requireNFTsBelongToUser(uint256[] memory nftIds, address userWalletAddress) external;
    function upgradeParcels(uint256[] memory tokenIds) external;
    function upgradedParcelsMapping(uint256 parcelId) external view returns(bool);
}

// SPDX-License-Identifier: MIT

import "./IERC165.sol";
import "./IERC721Lockable.sol";
import "./IERC721Metadata.sol";

pragma solidity ^0.8.15;

interface IERC721Base is IERC165, IERC721Lockable, IERC721Metadata {
    /**
     * @dev This event is emitted when token is transfered
     * @param _from address of the user from whom token is transfered
     * @param _to address of the user who will recive the token
     * @param _tokenId id of the token which will be transfered
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev This event is emitted when user is approved for token
     * @param _owner address of the owner of the token
     * @param _approval address of the user who gets approved
     * @param _tokenId id of the token that gets approved
     */
    event Approval(address indexed _owner, address indexed _approval, uint256 indexed _tokenId);

    /**
     * @dev This event is emitted when an address is approved/disapproved for another user's tokens
     * @param _owner address of the user whos tokens are being approved/disapproved to be used
     * @param _operator address of the user who gets approved/disapproved
     * @param _approved true - approves, false - disapproves
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Total amount of nft tokens in circulation
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gives the number of nft tokens that a given user owns
     * @param _owner address of the user who's token's count will be returned
     * @return amount of tokens given user owns
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @notice Tells weather a token exists
     * @param _tokenId id of the token who's existence is returned
     * @return true - exists, false - does not exist
     */
    function exists(uint256 _tokenId) external view returns (bool);

    /**
     * @notice Gives owner address of a given token
     * @param _tokenId id of the token who's owner address is returned
     * @return address of the given token owner
     */
    function ownerOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Transfers token and checkes weather it was recieved if reciver is ERC721Reciver contract
     *         Only authorized users can call this function
     *         Only unlocked tokens can be used to transfer
     * @dev When calling "onERC721Received" function passes "_data" from this function arguments
     * @param _from address of the user from whom token is transfered
     * @param _to address of the user who will recive the token
     * @param _tokenId id of the token which will be transfered
     * @param _data argument which will be passed to "onERC721Received" function
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external;

    /**
     * @notice Transfers token and checkes weather it was recieved if reciver is ERC721Reciver contract
     *         Only authorized users can call this function
     *         Only unlocked tokens can be used to transfer
     * @dev When calling "onERC721Received" function passes an empty string for "data" parameter
     * @param _from address of the user from whom token is transfered
     * @param _to address of the user who will recive the token
     * @param _tokenId id of the token which will be transfered
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /**
     * @notice Transfers token without checking weather it was recieved
     *         Only authorized users can call this function
     *         Only unlocked tokens can be used to transfer
     * @dev Does not call "onERC721Received" function even if the reciver is ERC721TokenReceiver
     * @param _from address of the user from whom token is transfered
     * @param _to address of the user who will recive the token
     * @param _tokenId id of the token which will be transfered
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /**
     * @notice Approves an address to use given token
     *         Only authorized users can call this function
     * @dev Only one user can be approved at any given moment
     * @param _approved address of the user who gets approved
     * @param _tokenId id of the token the given user get aproval on
     */
    function approve(address _approved, uint256 _tokenId) external;

    /**
     * @notice Approves or disapproves an address to use all tokens of the caller
     * @param _operator address of the user who gets approved/disapproved
     * @param _approved true - approves, false - disapproves
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Gives the approved address of the given token
     * @param _tokenId id of the token who's approved user is returned
     * @return address of the user who is approved for the given token
     */
    function getApproved(uint256 _tokenId) external view returns (address);

    /**
     * @notice Tells weather given user (_operator) is approved to use tokens of another given user (_owner)
     * @param _owner address of the user who's tokens are checked to be aproved to another user
     * @param _operator address of the user who's checked to be approved by owner of the tokens
     * @return true - approved, false - disapproved
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    /**
     * @notice Tells weather given user (_operator) is approved to use given token (_tokenId)
     * @param _operator address of the user who's checked to be approved for given token
     * @param _tokenId id of the token for which approval will be checked
     * @return true - approved, false - disapproved
     */
    function isAuthorized(address _operator, uint256 _tokenId) external view returns (bool);

    /// @notice Returns the purchase date for this NFT
    function getUserPurchaseTime(address _user) external view returns (uint256[2] memory);

    /// @notice Returns all the token IDs belonging to this user
    function tokensOf(address _owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IMinerNFT {
    function mintMiners(address _user, uint256 _count) external returns(uint256, uint256);
    function upgradeMinerLevels(uint256 _minerId, uint256 _levels) external;
    function balanceOf(address _owner) external view returns (uint256);
    function minerIdToLevelMapping(uint256 _tokenId) external view returns(uint256);
    function hashrate(uint256 _minerId) external pure returns (uint256);
    function mint(address) external returns (uint256);
    function lastMinerId() external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IMining {
    struct UserInfo {
        uint256 hashrate; 
        uint256 totalClaims;
        uint256 rewardDebt;
    }
    function deposit(address _user, uint256 _miner, uint256 _hashRate) external;
    function depositMiners(address _user, uint256 _firstMinerId, uint256 _minersCount, uint256 _hashRate) external;
    function withdraw(address _user,uint256 _miner) external;
    function applyVouchers(address _user, uint256[] calldata _minerIds) external;
    function getMinersCount(address _user) external view returns (uint256);
    function repairMiners(address _user) external;
    function increaseHashrate(address _userAddress, uint256 _hashrate) external;
    function decreaseHashrate(address _userAddress, uint256 _hashrate) external;
    function userHashrate(address _user) external view returns(uint256);
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
interface IERC20PermitUpgradeable {
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

pragma solidity 0.8.15;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC165 {
    /**
     * @notice Returns weather contract supports fiven interface
     * @dev This contract supports ERC165 and ERC721 interfaces
     * @param _interfaceId id of the interface which is checked to be supported
     * @return true - given interface is supported, false - given interface is not supported
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC721Lockable {
    /**
     * @dev Event that is emitted when token lock status is set
     * @param _tokenId id of the token who's lock status is set
     * @param _lock true - is locked, false - is not locked
     */
    event LockStatusSet(uint256 _tokenId, bool _lock);

    /**
     * @notice Tells weather a token is locked
     * @param _tokenId id of the token who's lock status is returned
     * @return true - is locked, false - is not locked
     */
    function isLocked(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function baseURI() external view returns (string memory);
}