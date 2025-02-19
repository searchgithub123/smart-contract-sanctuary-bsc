// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface INST {
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);
}

interface INFT {
    function activateCard(address account) external returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function cardPrice(uint256 tokenId) external view returns (uint256);

    function cardDurable(uint256 tokenId) external view returns (uint256);

    function mintTo(
        address _user,
        uint256 id,
        uint256 _price
    ) external returns (uint256);
}

library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

contract NMTGAME {
    address public owner;

    address public immutable nmtAddress;
    address public immutable nftAddress;

    address public marketAddress;
    mapping(uint256 => uint256) public priceOf;

    mapping(uint256 => address) public cardOwner;
    mapping(uint256 => uint256) public cardPrice;

    constructor(
        address _nmtAddress,
        address _nftAddress
    ) {
        owner = payable(msg.sender);
        nmtAddress = _nmtAddress;
        nftAddress = _nftAddress;

        priceOf[1] = 5 * 1e18;
        priceOf[2] = 100 * 1e18;

        marketAddress = address(this);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        TransferHelper.safeTransfer(token, to, amount);
    }

    function setOwner(address payable new_owner) external onlyOwner {
        owner = new_owner;
    }

    function setPrice(uint256 _id, uint256 _price) external onlyOwner {
        require(_id > 0, "id error");
        priceOf[_id] = _price;
    }

    function setMarketAddress(address marketAddress_) external onlyOwner {
        marketAddress = marketAddress_;
    }

    function mintToCaller(address _user, uint256 id)
        external
        returns (uint256)
    {
        uint256 _price = priceOf[id];
        if (_price > 0) {
            TransferHelper.safeTransferFrom(
                nmtAddress,
                msg.sender,
                marketAddress,
                _price
            );
        }

        uint256 nftId = INFT(nftAddress).mintTo(_user, id, _price);
        cardPrice[nftId] = _price;
        cardOwner[nftId] = _user;

        return nftId;
    }
}