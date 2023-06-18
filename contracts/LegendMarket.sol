// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.9;

import "./GlobalLegendAccessControl.sol";
import "./LegendCollection.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LegendFulfillment.sol";

contract LegendMarket {
    LegendCollection private _legendCollection;
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
    event LegendFulfillmentUpdated(
        address indexed oldLegendFulfillment,
        address indexed newLegendFulfillment,
        address updater
    );
    event TokensBought(
        uint256[] collectionIds,
        uint256[] amounts,
        address buyer,
        address[] chosenAddress
    );
    event OrderIsFulfilled(uint256 indexed _orderId, address _fulfillerAddress);

    event OrderCreated(
        uint256 indexed orderId,
        uint256 totalPrice,
        address buyer,
        string fulfillmentInformation,
        uint256 fulfillerId
    );
    event UpdateOrderDetails(
        uint256 indexed _orderId,
        string newOrderDetails,
        address buyer
    );
    event UpdateOrderStatus(
        uint256 indexed _orderId,
        string newOrderStatus,
        address buyer
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
        string memory _symbol,
        string memory _name
    ) {
        _legendCollection = LegendCollection(_collectionContract);
        _accessControl = GlobalLegendAccessControl(_accessControlContract);
        _legendFulfillment = LegendFulfillment(_fulfillmentContract);
        symbol = _symbol;
        name = _name;
        _orderSupply = 0;
    }

    function buyTokens(
        uint256[] memory _amounts,
        uint256[] memory _collectionIds,
        address[] memory _chosenTokenAddresses,
        string memory _fulfillmentDetails
    ) external {
        require(
            _chosenTokenAddresses.length == (_collectionIds.length) &&
                _chosenTokenAddresses.length == _amounts.length,
            "LegendMarket: Must provide an amount and token address for each collectionId."
        );

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            if (
                _legendCollection.getCollectionGrantCollectorsOnly(
                    _collectionIds[i]
                )
            ) {
                require(
                    IDynamicNFT(
                        _legendCollection.getCollectionDynamicNFTAddress(
                            _collectionIds[i]
                        )
                    ).getCollectorClaimedNFT(msg.sender),
                    "LegendMarket: Must be authorized grant collector."
                );
            }

            require(
                _legendCollection.getCollectionTokensMinted(_collectionIds[i]) +
                    _amounts[i] <
                    _legendCollection.getCollectionAmount(_collectionIds[i]),
                "LegendMarket: No more tokens can be bought from this collection."
            );

            bool isAccepted = false;
            address[] memory acceptedTokens = _legendCollection
                .getCollectionAcceptedTokens(_collectionIds[i]);
            for (uint256 j = 0; j < acceptedTokens.length; j++) {
                if (acceptedTokens[j] == _chosenTokenAddresses[i]) {
                    isAccepted = true;
                    break;
                }
            }
            require(
                isAccepted,
                "LegendMarket: Chosen token address is not an accepted token for the collection"
            );
        }

        uint256[] memory prices = new uint256[](_collectionIds.length);

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            address[] memory acceptedTokens = _legendCollection
                .getCollectionAcceptedTokens(_collectionIds[i]);
            for (uint256 j = 0; j < acceptedTokens.length; j++) {
                if (acceptedTokens[j] == _chosenTokenAddresses[i]) {
                    prices[i] = _legendCollection.getCollectionBasePrices(
                        _collectionIds[i]
                    )[j];

                    if (
                        _legendCollection.getCollectionDiscount(
                            _collectionIds[i]
                        ) !=
                        0 &&
                        IDynamicNFT(
                            _legendCollection.getCollectionDynamicNFTAddress(
                                _collectionIds[i]
                            )
                        ).getCollectorClaimedNFT(msg.sender)
                    ) {
                        prices[i] =
                            prices[i] -
                            ((prices[i] *
                                _legendCollection.getCollectionDiscount(
                                    _collectionIds[i]
                                )) / 100);
                    }

                    break;
                }
            }
        }

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            uint256 allowance = IERC20(_chosenTokenAddresses[i]).allowance(
                msg.sender,
                address(this)
            );

            require(
                allowance >= prices[i],
                "LegendMarket: Insufficient Approval Allowance"
            );

            uint256 _fulfillerId = _legendCollection.getCollectionFulfillerId(
                _collectionIds[i]
            );
            IERC20(_chosenTokenAddresses[i]).transferFrom(
                msg.sender,
                _legendCollection.getCollectionCreator(_collectionIds[i]),
                prices[i] -
                    ((prices[i] *
                        (
                            _legendFulfillment.getFulfillerPercent(_fulfillerId)
                        )) / 100)
            );
            IERC20(_chosenTokenAddresses[i]).transferFrom(
                msg.sender,
                _legendFulfillment.getFulfillerAddress(_fulfillerId),
                ((prices[i] *
                    (_legendFulfillment.getFulfillerPercent(_fulfillerId))) /
                    100)
            );

            _legendCollection.purchaseAndMintToken(
                _collectionIds,
                _amounts,
                msg.sender
            );

            _orderSupply++;

            uint256[] memory _tokenIds = _legendCollection
                .getCollectionTokenIds(_collectionIds[i]);

            Order memory newOrder = Order({
                orderId: _orderSupply,
                tokenId: _tokenIds[_tokenIds.length - 1],
                details: _fulfillmentDetails,
                buyer: msg.sender,
                chosenAddress: _chosenTokenAddresses[i],
                timestamp: block.timestamp,
                status: "ordered",
                isFulfilled: false,
                fulfillerId: _fulfillerId
            });

            _orders[_orderSupply] = newOrder;

            emit OrderCreated(
                _orderSupply,
                prices[i],
                msg.sender,
                _fulfillmentDetails,
                _fulfillerId
            );

            _tokensSold[_collectionIds[i]] += 1;
            _tokenIdsSold[_collectionIds[i]].push(
                _tokenIds[_tokenIds.length - 1]
            );
        }

        emit TokensBought(
            _collectionIds,
            _amounts,
            msg.sender,
            _chosenTokenAddresses
        );
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

    function updateLegendFulfillment(address _newLegendFulfillmentAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendFulfillment);
        _legendFulfillment = LegendFulfillment(_newLegendFulfillmentAddress);
        emit LegendFulfillmentUpdated(
            oldAddress,
            _newLegendFulfillmentAddress,
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
        emit OrderIsFulfilled(_orderId, msg.sender);
    }

    function setOrderStatus(uint256 _orderId, string memory _status)
        external
        onlyFulfiller(_orders[_orderId].fulfillerId)
    {
        _orders[_orderId].status = _status;
        emit UpdateOrderStatus(_orderId, _status, msg.sender);
    }

    function setOrderDetails(uint256 _orderId, string memory _newDetails)
        external
    {
        require(
            _orders[_orderId].buyer == msg.sender,
            "LegendMarket: Only the buyer can update their order details."
        );
        _orders[_orderId].details = _newDetails;
        emit UpdateOrderDetails(_orderId, _newDetails, msg.sender);
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getLegendCollectionContract() public view returns (address) {
        return address(_legendCollection);
    }

    function getLegendFulfillmentContract() public view returns (address) {
        return address(_legendFulfillment);
    }
}
