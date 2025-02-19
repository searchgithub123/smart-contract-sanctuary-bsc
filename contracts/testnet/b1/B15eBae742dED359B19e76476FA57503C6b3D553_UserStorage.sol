// SPDX-License-Identifier: MIT
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity ^0.8.0;
contract UserStorage is Ownable {
    struct User {
        address userAddr;
        string avatar;
        string email;
        uint256 isOnline;
        uint256 userFlag;
        uint256 credit;
        uint256 regTime;
        TradeStats tradeStats;
        MorgageStats morgageStats;
    }
    struct TradeStats {
        uint256 tradeTotal;
        uint256 restTotal;
    }
    struct MorgageStats {
        uint256 mortgage;
        uint256 freezeMortgage;
        uint256 relieveMortgage;
        uint256 inviteUserCount;
        uint256 inviteUserReward;
        uint256 applyRelieveTime;
        uint256 handleRelieveTime;
    }
    mapping(address => User) public users;
    mapping(address => uint256) public userIndex;

    User[] public userList;

    address public recipient;
    uint256 public feeAmount;

    event addUser(address _userAddr);
    event updateUser(string _avatar, string _email, uint256 _isOnline);

    address _restCAddr;
    address _orderCAddr;
    address _recordCAddr;
    address _appealCAddr;

    modifier onlyAuthFromAddr() {
        require(_restCAddr != address(0), "Invalid address call rest");
        require(_orderCAddr != address(0), "Invalid address call order");
        require(_recordCAddr != address(0), "Invalid address call record");
        require(_appealCAddr != address(0), "Invalid address call appeal");
        _;
    }

    function setFee(address _addr, uint256 _amount) external onlyOwner {
        recipient = _addr;
        feeAmount = _amount;
    }

    function authFromContract(
        address _fromRest,
        address _fromOrder,
        address _fromRecord,
        address _fromAppeal
    ) external onlyOwner {
        _restCAddr = _fromRest;
        _orderCAddr = _fromOrder;
        _recordCAddr = _fromRecord;
        _appealCAddr = _fromAppeal;
    }

    modifier onlyMemberOf() {
        require(users[msg.sender].userAddr != address(0), "has no permission");
        _;
    }

    function _insert(address _addr) internal {
        require(_addr != address(0), "UserStorage: addr null is not allowed");
        require(
            users[_addr].userAddr == address(0),
            "UserStorage: current User exist"
        );

        TradeStats memory tradeStats = TradeStats({
            tradeTotal: 0,
            restTotal: 0
        });
        MorgageStats memory morgageStats = MorgageStats({
            mortgage: 0,
            freezeMortgage: 0,
            relieveMortgage: 0,
            inviteUserCount: 0,
            inviteUserReward: 0,
            applyRelieveTime: 0,
            handleRelieveTime: 0
        });

        User memory u = User({
            userAddr: _addr,
            avatar: "",
            email: "",
            isOnline: 1,
            userFlag: 0,
            credit: 0,
            regTime: block.timestamp,
            tradeStats: tradeStats,
            morgageStats: morgageStats
        });
        users[_addr] = u;

        userList.push(u);
        userIndex[_addr] = userList.length - 1;
        emit addUser(_addr);
    }

    function _updateInfo(
        address _addr,
        string memory _avatar,
        string memory _email,
        uint256 _isOnline
    ) internal {
        require(_addr != address(0), "UserStorage: _addr null is not allowed");
        require(
            users[_addr].userAddr != address(0),
            "UserStorage: current User not exist"
        );

        User memory u = users[_addr];
        if (bytes(_avatar).length != 0) {
            u.avatar = _avatar;
        }
        if (bytes(_email).length != 0) {
            u.email = _email;
        }

        if (_isOnline != uint256(0)) {
            u.isOnline = _isOnline;
        }

        users[_addr] = u;
        userList[userIndex[_addr]] = u;
    }

    function _updateTradeStats(
        address _addr,
        TradeStats memory _tradeStats,
        uint256 _credit
    ) internal {
        require(_addr != address(0), "UserStorage: _addr null is not allowed");
        require(
            users[_addr].userAddr != address(0),
            "UserStorage: current User not exist"
        );

        User memory u = users[_addr];

        u.credit = _credit;

        u.tradeStats.tradeTotal = _tradeStats.tradeTotal;

        u.tradeStats.restTotal = _tradeStats.restTotal;

        users[_addr] = u;
        userList[userIndex[_addr]] = u;
    }

    function _updateMorgageStats(
        address _addr,
        MorgageStats memory _morgageStats
    ) internal {
        require(_addr != address(0), "UserStorage: _addr null is not allowed");
        require(
            users[_addr].userAddr != address(0),
            "UserStorage: current User not exist"
        );

        User memory u = users[_addr];

        u.morgageStats.mortgage = _morgageStats.mortgage;
        u.morgageStats.freezeMortgage = _morgageStats.freezeMortgage;
        u.morgageStats.relieveMortgage = _morgageStats.relieveMortgage;
        u.morgageStats.inviteUserCount = _morgageStats.inviteUserCount;
        u.morgageStats.inviteUserReward = _morgageStats.inviteUserReward;
        u.morgageStats.applyRelieveTime = _morgageStats.applyRelieveTime;
        u.morgageStats.handleRelieveTime = _morgageStats.handleRelieveTime;

        users[_addr] = u;
        userList[userIndex[_addr]] = u;
    }

    function _search(address _addr) internal view returns (User memory user) {
        require(_addr != address(0), "UserStorage: _addr null is not allowed");
        require(
            users[_addr].userAddr != address(0),
            "UserStorage: current User not exist"
        );

        User memory a = users[_addr];
        return a;
    }

    function register() external payable {
        require(!isMemberOf(), "has registed");

        if (feeAmount > 0) {
            require(recipient != address(0), "recipient null is not allowed");
            require(msg.value >= feeAmount, "insufficient balance");
            payable(recipient).transfer(feeAmount);
        }
        _insert(msg.sender);
    }

    function isMemberOf() public view returns (bool) {
        return (users[msg.sender].userAddr != address(0));
    }

    function updateInfo(
        string memory _avatar,
        string memory _email,
        uint256 _isOnline
    ) external onlyMemberOf {
        _updateInfo(msg.sender, _avatar, _email, _isOnline);
        emit updateUser(_avatar, _email, _isOnline);
    }

    function updateTradeStats(
        address _addr,
        TradeStats memory _tradeStats,
        uint256 _credit
    ) public onlyAuthFromAddr {
        require(
            msg.sender == _restCAddr ||
                msg.sender == _orderCAddr ||
                msg.sender == _appealCAddr ||
                msg.sender == _recordCAddr,
            "UserStorage:Invalid from contract address"
        );
        _updateTradeStats(_addr, _tradeStats, _credit);
    }

    function updateMorgageStats(
        address _addr,
        MorgageStats memory _morgageStats
    ) public onlyAuthFromAddr {
        require(
            msg.sender == _recordCAddr,
            "UserStorage:Invalid from contract address"
        );
        _updateMorgageStats(_addr, _morgageStats);
    }

    function updateUserRole(address _addr, uint256 _userFlag)
        public
        onlyAuthFromAddr
    {
        require(
            msg.sender == _recordCAddr,
            "UserStorage:Invalid from contract address"
        );
        require(_addr != address(0), "UserStorage: _addr null is not allowed");
        require(
            users[_addr].userAddr != address(0),
            "UserStorage: current User not exist"
        );

        require(_userFlag <= 3, "UserStorage: Invalid userFlag 3");

        User memory u = users[_addr];
        u.userFlag = _userFlag;
        users[_addr] = u;
        userList[userIndex[_addr]] = u;
    }

    function searchUser(address _addr)
        external
        view
        returns (User memory user)
    {
        return _search(_addr);
    }

    function searchUserList() external view returns (User[] memory) {
        return userList;
    }
}