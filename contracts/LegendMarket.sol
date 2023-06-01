// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./GlobalLegendAccessControl.sol";
import "./LegendCollection.sol";
import "./LegendEscrow.sol";
import "./LegendNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LegendFulfillment.sol";

contract LegendMarket {
    LegendCollection private _legendCollection;
    LegendEscrow private _legendEscrow;
    LegendNFT private _legendNFT;
    GlobalLegendAccessControl private _accessControl;
    LegendFulfillment private _legendFulfillment;
    uint256 private _orderSupply;
    string public symbol;
    string public name;

    struct Order {
        uint256 orderId;
        uint256 tokenId;
        string details;
        address buyer;
        address chosenAddress;
        uint256 timestamp;
        string status;
        bool isFulfilled;
        uint256 fulfillerId;
    }

    mapping(uint256 => uint256) private _tokensSold;
    mapping(uint256 => uint256[]) private _tokenIdsSold;
    mapping(uint256 => Order) private _orders;

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyFulfiller(uint256 _fulfillerId) {
        require(
            _legendFulfillment.getFulfillerAddress(_fulfillerId) == msg.sender,
            "LegendMarket: Only the fulfiller can update this status."
        );
        _;
    }

    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );
    event LegendCollectionUpdated(
        address indexed oldLegendCollection,
        address indexed newLegendCollection,
        address updater
    );
    event LegendNFTUpdated(
        address indexed oldLegendNFT,
        address indexed newLegendNFT,
        address updater
    );
    event LegendEscrowUpdated(
        address indexed oldLegendEscrow,
        address indexed newLegendEscrow,
        address updater
    );
    event TokensBought(
        uint256[] tokenIds,
        address buyer,
        address chosenAddress
    );

    event OrderCreated(
        uint256 indexed orderId,
        address buyer,
        string fulfillmentInformation
    );

    event FulfillerAddressUpdated(
        uint256 indexed fulfillerId,
        address newFulfillerAddress
    );

    event FulfillerPercentUpdated(
        uint256 indexed fulfillerId,
        uint256 newFulfillerPercent
    );

    constructor(
        address _collectionContract,
        address _accessControlContract,
        address _fulfillmentContract,
        address _NFTContract,
        string memory _symbol,
        string memory _name
    ) {
        _legendCollection = LegendCollection(_collectionContract);
        _accessControl = GlobalLegendAccessControl(_accessControlContract);
        _legendNFT = LegendNFT(_NFTContract);
        _legendFulfillment = LegendFulfillment(_fulfillmentContract);
        symbol = _symbol;
        name = _name;
        _orderSupply = 0;
    }

    function buyTokens(
        uint256[] memory _tokenIds,
        address _chosenTokenAddress,
        string memory _fulfillmentDetails
    ) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_legendNFT.getTokenGrantCollectorsOnly(_tokenIds[i])) {
                require(
                    IDynamicNFT(_legendNFT.getTokenDynamicNFTAddress(_tokenIds[i]))
                        .getCollectorClaimedNFT(msg.sender),
                    "LegendMarket: Must be authorized grant collector."
                );
            }
        }

        uint256 totalPrice = 0;
        uint256[] memory prices = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _legendNFT.ownerOf(_tokenIds[i]) == address(_legendEscrow),
                "LegendMarket: Token must be owned by Escrow"
            );
            bool isAccepted = false;
            address[] memory acceptedTokens = _legendNFT.getTokenAcceptedTokens(
                _tokenIds[i]
            );
            for (uint256 j = 0; j < acceptedTokens.length; j++) {
                if (acceptedTokens[j] == _chosenTokenAddress) {
                    isAccepted = true;
                    break;
                }
            }
            require(
                isAccepted,
                "LegendMarket: Chosen token address is not an accepted token for the collection"
            );
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address[] memory acceptedTokens = _legendNFT.getTokenAcceptedTokens(
                _tokenIds[i]
            );
            for (uint256 j = 0; j < acceptedTokens.length; j++) {
                if (acceptedTokens[j] == _chosenTokenAddress) {
                    prices[i] = _legendNFT.getBasePrices(_tokenIds[i])[j];

                    if (
                        _legendNFT.getTokenDiscount(_tokenIds[i]) != 0 &&
                        IDynamicNFT(
                            _legendNFT.getTokenDynamicNFTAddress(_tokenIds[i])
                        ).getCollectorClaimedNFT(msg.sender)
                    ) {
                        totalPrice +=
                            prices[i] *
                            _legendNFT.getTokenDiscount(_tokenIds[i]);
                    } else {
                        totalPrice += prices[i];
                    }

                    break;
                }
            }
        }

        uint256 allowance = IERC20(_chosenTokenAddress).allowance(
            msg.sender,
            address(this)
        );

        require(
            allowance >= totalPrice,
            "LegendMarket: Insufficient Approval Allowance"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _fulfillerId = _legendNFT.getTokenFulfillerId(_tokenIds[i]);
            IERC20(_chosenTokenAddress).transferFrom(
                msg.sender,
                _legendNFT.getTokenCreator(_tokenIds[i]),
                prices[i] -
                    prices[i] *
                    _legendFulfillment.getFulfillerPercent(_fulfillerId)
            );
            IERC20(_chosenTokenAddress).transferFrom(
                msg.sender,
                _legendFulfillment.getFulfillerAddress(_fulfillerId),
                prices[i] * _legendFulfillment.getFulfillerPercent(_fulfillerId)
            );
            _legendEscrow.release(_tokenIds[i], false, msg.sender);

            _orderSupply++;

            Order memory newOrder = Order({
                orderId: _orderSupply,
                tokenId: _tokenIds[i],
                details: _fulfillmentDetails,
                buyer: msg.sender,
                chosenAddress: _chosenTokenAddress,
                timestamp: block.timestamp,
                status: "ordered",
                isFulfilled: false,
                fulfillerId: _fulfillerId
            });

            _orders[_orderSupply] = newOrder;

            emit OrderCreated(_orderSupply, msg.sender, _fulfillmentDetails);
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _tokensSold[_legendNFT.getTokenCollection(_tokenIds[i])] += 1;
            _tokenIdsSold[_legendNFT.getTokenCollection(_tokenIds[i])].push(
                _tokenIds[i]
            );
        }

        emit TokensBought(_tokenIds, msg.sender, _chosenTokenAddress);
    }

    function updateAccessControl(address _newAccessControlAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function updateLegendCollection(address _newLegendCollectionAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendCollection);
        _legendCollection = LegendCollection(_newLegendCollectionAddress);
        emit LegendCollectionUpdated(
            oldAddress,
            _newLegendCollectionAddress,
            msg.sender
        );
    }

    function updateLegendNFT(address _newLegendNFTAddress) external onlyAdmin {
        address oldAddress = address(_legendNFT);
        _legendNFT = LegendNFT(_newLegendNFTAddress);
        emit LegendNFTUpdated(oldAddress, _newLegendNFTAddress, msg.sender);
    }

    function setLegendEscrow(address _newLegendEscrowAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendEscrow);
        _legendEscrow = LegendEscrow(_newLegendEscrowAddress);
        emit LegendEscrowUpdated(
            oldAddress,
            _newLegendEscrowAddress,
            msg.sender
        );
    }

    function getCollectionSoldCount(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _tokensSold[_collectionId];
    }

    function getTokensSoldCollection(uint256 _collectionId)
        public
        view
        returns (uint256[] memory)
    {
        return _tokenIdsSold[_collectionId];
    }

    function getOrderTokenId(uint256 _orderId) public view returns (uint256) {
        return _orders[_orderId].tokenId;
    }

    function getOrderDetails(uint256 _orderId)
        public
        view
        returns (string memory)
    {
        return _orders[_orderId].details;
    }

    function getOrderBuyer(uint256 _orderId) public view returns (address) {
        return _orders[_orderId].buyer;
    }

    function getOrderChosenAddress(uint256 _orderId)
        public
        view
        returns (address)
    {
        return _orders[_orderId].chosenAddress;
    }

    function getOrderTimestamp(uint256 _orderId) public view returns (uint256) {
        return _orders[_orderId].timestamp;
    }

    function getOrderStatus(uint256 _orderId)
        public
        view
        returns (string memory)
    {
        return _orders[_orderId].status;
    }

    function getOrderIsFulfilled(uint256 _orderId) public view returns (bool) {
        return _orders[_orderId].isFulfilled;
    }

    function getOrderFulfillerId(uint256 _orderId)
        public
        view
        returns (uint256)
    {
        return _orders[_orderId].fulfillerId;
    }

    function getOrderSupply() public view returns (uint256) {
        return _orderSupply;
    }

    function setOrderisFulfilled(uint256 _orderId)
        external
        onlyFulfiller(_orders[_orderId].fulfillerId)
    {
        _orders[_orderId].isFulfilled = true;
    }

    function setOrderStatus(uint256 _orderId, string memory _status)
        external
        onlyFulfiller(_orders[_orderId].fulfillerId)
    {
        _orders[_orderId].status = _status;
    }

    function setOrderDetails(uint256 _orderId, string memory _newDetails)
        external
    {
        require(
            _orders[_orderId].buyer == msg.sender,
            "LegendMarket: Only the buyer can update their order details."
        );
        _orders[_orderId].details = _newDetails;
    }
}
