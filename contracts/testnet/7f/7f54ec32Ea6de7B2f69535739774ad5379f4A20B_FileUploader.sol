/**
 *Submitted for verification at BscScan.com on 2022-11-25
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-20
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/File_Upload.sol

//SPDX-License-Identifier:MIT
pragma solidity>=0.8.0;


contract FileUploader is Ownable
{
    struct account
    {
        string username;
        string password;
        string[] policies;
    }

    mapping (string => account)accounts;
    mapping (string => bool)UserCheck;

    modifier doesUserExist(string memory _username)
    {
        require(UserCheck[_username] != false,"User does not exist");
        _;
    }

    function setAccount(string memory _username,string memory _password)public onlyOwner
    {
        require(UserCheck[_username] == false,"Username is already taken");
        UserCheck[_username] = true;
        accounts[_username].username = _username;
        accounts[_username].password = _password;
    }

    function addPolicy(string memory _username,string memory _ipfshash) public doesUserExist(_username) onlyOwner
    {
        accounts[_username].policies.push(_ipfshash);
    }

    function changePassword(string memory _username,string memory _password)public doesUserExist(_username) onlyOwner
    {
        accounts[_username].password = _password;
    }

    function getPolicies(string memory _username,string memory _password) public view doesUserExist(_username) returns(string[] memory)
    {
        require(keccak256(abi.encodePacked(accounts[_username].password)) == keccak256(abi.encodePacked(_password)),"Invalid password");
        return accounts[_username].policies;       
    }

}