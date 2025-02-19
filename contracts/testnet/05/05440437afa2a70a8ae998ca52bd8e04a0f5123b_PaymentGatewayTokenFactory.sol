/**
 *Submitted for verification at BscScan.com on 2023-02-13
*/

// SPDX-License-Identifier: MIT
// File: contracts/Owner.sol


pragma solidity >=0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {
  address private owner;

  // event for EVM logging
  event OwnerSet(address indexed oldOwner, address indexed newOwner);

  // modifier to check if caller is owner
  modifier isOwner() {
    // If the first argument of 'require' evaluates to 'false', execution terminates and all
    // changes to the state and to Ether balances are reverted.
    // This used to consume all gas in old EVM versions, but not anymore.
    // It is often a good idea to use 'require' to check if functions are called correctly.
    // As a second argument, you can also provide an explanation about what went wrong.
    require(msg.sender == owner, "Caller is not owner");
    _;
  }

  /**
   * @dev Set contract deployer as owner
   */
  constructor() {
    owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    emit OwnerSet(address(0), owner);
  }

  /**
   * @dev Change owner
   * @param newOwner address of new owner
   */
  function changeOwner(address newOwner) public isOwner {
    emit OwnerSet(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Return owner address
   * @return address of owner
   */
  function getOwner() external view returns (address) {
    return owner;
  }
}

// File: contracts/ERC20.sol



pragma solidity >=0.8.14;

interface ERC20 {
  function totalSupply() external returns (uint256);

  function balanceOf(address tokenOwner) external returns (uint256 balance);

  function allowance(address tokenOwner, address spender)
    external
    returns (uint256 remaining);

  function transfer(address to, uint256 tokens) external returns (bool success);

  function approve(address spender, uint256 tokens)
    external
    returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) external returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint256 tokens
  );
}

// File: contracts/PaymentGatewayToken.sol


pragma solidity >=0.8.14;


contract PaymentGatewayToken is Owner {
  event OrderEvent(string merchantId, string orderId, uint256 amount);

  event WithdrawEvent(string merchantId, uint256 amount);

  string public name;
  string public merchantId;
  address public vndtToken;

  constructor(
    string memory _name,
    string memory _merchantId,
    address _vndtToken,
    address _owner
  ) {
    name = _name;
    merchantId = _merchantId;
    vndtToken = _vndtToken;
    changeOwner(_owner);
  }

  function pay(uint256 amount, string memory orderId) public {
    // Event
    ERC20(vndtToken).transferFrom(msg.sender, address(this), amount);
    emit OrderEvent(merchantId, orderId, amount);

    // Event
    ERC20(vndtToken).transfer(this.getOwner(), amount);
    emit WithdrawEvent(merchantId, amount);
  }
}

// File: contracts/PaymentGatewayTokenFactory.sol


pragma solidity >=0.8.14;


contract PaymentGatewayTokenFactory is Owner {
  address[] public gateways;

  event ContractCreated(address gateway);

  function createForToken(
    string memory name,
    string memory merchantId,
    address vndtToken,
    address owner
  ) public isOwner {
    PaymentGatewayToken gateway = new PaymentGatewayToken(
      name,
      merchantId,
      vndtToken,
      owner
    );
    gateways.push(address(gateway));
    emit ContractCreated(address(gateway));
  }

  function getGateways() public view returns (address[] memory) {
    return gateways;
  }
}