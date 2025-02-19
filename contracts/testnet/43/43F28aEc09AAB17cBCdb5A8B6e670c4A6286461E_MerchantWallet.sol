/**
 *Submitted for verification at BscScan.com on 2022-05-30
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: MerchantWallet.sol



pragma solidity 0.8.14;



contract MerchantWallet is Ownable {
    //MetchantInteractionAddress 交互白名单地址
    address public merchantInteractionAddress;
    //MetchantCollectionAddress 收款白名单地址
    address public merchantCollectionAddress;
    //RefundAddress 退款地址
    address public refundAddress;
    //SignatureWalletAddress 验证签名的钱包地址
    address public signatureWalletAddress;
    //TransactionWalletAddress 发起交易的钱包地址
    address public transactionWalletAddress;

    /**
     * 这个mapping用来存储已消费的订单ID哈希值和对应的区块时间戳
     */
    mapping(bytes32 => uint256) public orderIdHashTimestampMapping;

    bool public safeMode = false;

    modifier inSafeMode() {
        require(safeMode, "This function needs to be run in SAFE mode!");
        _;
    }

    modifier notInSafeMode() {
        require(!safeMode, "This function needs to be run in UNSAFE mode!");
        _;
    }

    modifier isMerchantInteractionAddress() {
        require(
            msg.sender == merchantInteractionAddress,
            "Only merchant interaction address can call!"
        );
        _;
    }

    modifier isTransactionWalletAddress() {
        require(
            msg.sender == transactionWalletAddress,
            "Only transaction wallet address can call!"
        );
        _;
    }

    constructor(
        address _merchantInteractionAddress,
        address _merchantCollectionAddress,
        address _refundAddress,
        address _signatureWalletAddress,
        address _transactionWalletAddress
    ) {
        merchantInteractionAddress = _merchantInteractionAddress;
        merchantCollectionAddress = _merchantCollectionAddress;
        refundAddress = _refundAddress;
        signatureWalletAddress = _signatureWalletAddress;
        transactionWalletAddress = _transactionWalletAddress;
    }

    /**
     * 激活安全模式
     * modifiers：onlyOwner
     */
    function activateSafeMode() external onlyOwner {
        safeMode = true;
    }

    /**
     * 禁用安全模式
     * modifiers：onlyOwner
     */
    function deactivateSafeMode() external onlyOwner {
        safeMode = false;
    }

    /**
     * withdrawal
     * modifiers：notInSafeMode isMerchantInteractionAddress
     */
    function withdrawal(
        string calldata orderId,
        uint256 weiAmount,
        uint256 expirationTimestamp,
        bytes calldata signature
    ) external notInSafeMode isMerchantInteractionAddress {
        checkAndTransferCoin(
            orderId,
            weiAmount,
            expirationTimestamp,
            this.withdrawal.selector,
            signature,
            address(this),
            payable(merchantCollectionAddress)
        );
    }

    /**
     * refund
     * modifiers：isTransactionWalletAddress
     */
    function refund(
        string calldata orderId,
        uint256 weiAmount,
        uint256 expirationTimestamp,
        bytes calldata signature
    ) external isTransactionWalletAddress {
        checkAndTransferCoin(
            orderId,
            weiAmount,
            expirationTimestamp,
            this.refund.selector,
            signature,
            address(this),
            payable(refundAddress)
        );
    }

    /**
     * 更新交互白名单地址
     * modifiers：onlyOwner inSafeMode
     */
    function updateMerchantInteractionAddress(address newAddress)
        external
        onlyOwner
        inSafeMode
    {
        require(
            newAddress != address(0),
            "The newAddress field cannot be a zero address."
        );
        require(
            newAddress != merchantInteractionAddress,
            "The newAddress field cannot be equal to the previous value."
        );

        merchantInteractionAddress = newAddress;
    }

    /**
     * 更新收款白名单地址
     * modifiers：onlyOwner inSafeMode
     */
    function updateMerchantCollectionAddress(address newAddress)
        external
        onlyOwner
        inSafeMode
    {
        require(
            newAddress != address(0),
            "The newAddress field cannot be a zero address."
        );
        require(
            newAddress != merchantCollectionAddress,
            "The newAddress field cannot be equal to the previous value."
        );
        merchantCollectionAddress = newAddress;
    }

    /**
     * 更新退款地址
     * modifiers：onlyOwner
     */
    function updateRefundAddress(address newAddress) external onlyOwner {
        require(
            newAddress != address(0),
            "The newAddress field cannot be a zero address."
        );
        require(
            newAddress != refundAddress,
            "The newAddress field cannot be equal to the previous value."
        );
        refundAddress = newAddress;
    }

    /**
     * 更新验证签名的钱包地址
     * modifiers：onlyOwner inSafeMode
     */
    function updateSignatureWalletAddress(address newAddress)
        external
        onlyOwner
        inSafeMode
    {
        require(
            newAddress != address(0),
            "The newAddress field cannot be a zero address."
        );
        require(
            newAddress != signatureWalletAddress,
            "The newAddress field cannot be equal to the previous value."
        );
        signatureWalletAddress = newAddress;
    }

    /**
     * 更新发起交易的钱包地址
     * modifiers：onlyOwner inSafeMode
     */
    function updateTransactionWalletAddress(address newAddress)
        external
        onlyOwner
        inSafeMode
    {
        require(
            newAddress != address(0),
            "The newAddress field cannot be a zero address."
        );
        require(
            newAddress != transactionWalletAddress,
            "The newAddress field cannot be equal to the previous value."
        );
        transactionWalletAddress = newAddress;
    }

    function checkAndTransferCoin(
        string calldata orderId,
        uint256 weiAmount,
        uint256 expirationTimestamp,
        bytes4 methodId,
        bytes calldata signature,
        //easy for unit test
        address contractAddress,
        address payable recipient
    ) private {
        // 账户中是否有足够的数量coin
        require(
            contractAddress.balance >= weiAmount,
            "Insufficient withdrawal balance."
        );
        // 获取当前区块时间戳，判断是否超时
        uint256 current = block.timestamp;
        require(expirationTimestamp > current, "Timestamp has expired.");
        // 计算订单hash，判断是否存在
        bytes32 orderIdHash = keccak256(abi.encodePacked(orderId));
        require(
            orderIdHashTimestampMapping[orderIdHash] == 0,
            "The order ID has been consumed."
        );
        // 检查尝试恢复出的地址是否是配置签名地址
        bytes32 operationHash = keccak256(
            abi.encodePacked(
                orderId,
                weiAmount,
                block.chainid,
                contractAddress,
                expirationTimestamp,
                methodId
            )
        );
        address recovered = ECDSA.recover(operationHash, signature);
        require(
            recovered == signatureWalletAddress,
            "Please use the specified private key to sign."
        );
        // 写入storage
        orderIdHashTimestampMapping[orderIdHash] = current;
        // 尝试转款
        require(recipient != address(0), "");
        (bool success, ) = payable(recipient).call{value: weiAmount}("");
        require(success, "Transfer coin error.");
    }

    receive() external payable {}

    fallback() external payable {}
}