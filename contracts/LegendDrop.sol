// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./LegendCollection.sol";
import "./GlobalLegendAccessControl.sol";
import "hardhat/console.sol";

contract LegendDrop {
    GlobalLegendAccessControl private _accessControl;
    LegendCollection private _legendCollection;
    uint256 private _dropSupply;
    string public symbol;
    string public name;

    struct Drop {
        uint256 dropId;
        uint256[] collectionIds;
        string dropURI;
        address creator;
        uint256 timestamp;
    }

    mapping(uint256 => Drop) private _drops;
    mapping(uint256 => uint256) private _collectionIdToDrop;

    event DropCreated(
        uint256 indexed dropId,
        uint256[] collectionIds,
        address creator
    );

    event CollectionAddedToDrop(
        uint256 indexed dropId,
        uint256[] collectionIds
    );

    event CollectionRemovedFromDrop(
        uint256 indexed dropId,
        uint256 collectionId
    );

    event DropURIUpdated(uint256 indexed dropId, string dropURI);

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

    event DropDeleted(uint256 indexed dropId, address deleter);

    modifier onlyCreator(uint256[] memory _collectionIds) {
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            require(
                _legendCollection.getCollectionCreator(_collectionIds[i]) ==
                    msg.sender,
                "LegendDrop: Only the owner of a collection can add it to a drop"
            );
        }
        _;
    }

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    constructor(
        address _legendCollectionAddress,
        address _accessControlAddress,
        string memory _symbol,
        string memory _name
    ) {
        _legendCollection = LegendCollection(_legendCollectionAddress);
        _accessControl = GlobalLegendAccessControl(_accessControlAddress);
        _dropSupply = 0;
        symbol = _symbol;
        name = _name;
    }

    function createDrop(uint256[] memory _collectionIds, string memory _dropURI)
        external
    {
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            require(
                _legendCollection.getCollectionCreator(_collectionIds[i]) ==
                    msg.sender &&
                    (_accessControl.isWriter(msg.sender) ||
                        _accessControl.isAdmin(msg.sender)),
                "LegendDrop: Only the owner of a collection can add it to a drop"
            );
            require(
                _collectionIds[i] != 0 &&
                    _collectionIds[i] <=
                    _legendCollection.getCollectionSupply(),
                "LegendDrop: Collection does not exist"
            );
            require(
                _collectionIdToDrop[_collectionIds[i]] == 0,
                "LegendDrop: Collection is already part of another existing drop"
            );
        }

        _dropSupply++;

        Drop memory newDrop = Drop({
            dropId: _dropSupply,
            collectionIds: _collectionIds,
            dropURI: _dropURI,
            creator: msg.sender,
            timestamp: block.timestamp
        });

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            _collectionIdToDrop[_collectionIds[i]] = _dropSupply;
            _legendCollection.setCollectionDropId(
                _dropSupply,
                _collectionIds[i]
            );
        }

        _drops[_dropSupply] = newDrop;

        emit DropCreated(_dropSupply, _collectionIds, msg.sender);
    }

    function addCollectionToDrop(
        uint256 _dropId,
        uint256[] memory _collectionIds
    ) external onlyCreator(_collectionIds) {
        require(_drops[_dropId].dropId != 0, "LegendDrop: Drop does not exist");
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            require(
                _collectionIdToDrop[_collectionIds[i]] == 0,
                "LegendDrop: Collection is already part of another existing drop"
            );
        }

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            _drops[_dropId].collectionIds.push(_collectionIds[i]);
            _collectionIdToDrop[_collectionIds[i]] = _dropId;
            _legendCollection.setCollectionDropId(_dropId, _collectionIds[i]);
        }

        emit CollectionAddedToDrop(_dropId, _collectionIds);
    }

    function removeCollectionFromDrop(uint256 _collectionId) external {
        require(
            _drops[_collectionIdToDrop[_collectionId]].dropId != 0,
            "LegendDrop: Collection is not part of a drop"
        );
        require(
            _legendCollection.getCollectionCreator(_collectionId) ==
                msg.sender ||
                address(_legendCollection) == msg.sender,
            "LegendDrop: Only creator or collection contract can remove collection"
        );

        uint256[] storage collectionIds = _drops[
            _collectionIdToDrop[_collectionId]
        ].collectionIds;
        uint256 collectionIndex = findIndex(collectionIds, _collectionId);
        require(
            collectionIndex < collectionIds.length,
            "LegendDrop: Collection not found"
        );

        collectionIds[collectionIndex] = collectionIds[
            collectionIds.length - 1
        ];
        collectionIds.pop();

        emit CollectionRemovedFromDrop(
            _collectionIdToDrop[_collectionId],
            _collectionId
        );
    }

    function findIndex(uint256[] storage array, uint256 value)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }
        return array.length;
    }

    function deleteDrop(uint256 _dropId) external {
        require(_drops[_dropId].dropId != 0, "LegendDrop: Drop does not exist");
        for (uint256 i = 0; i < _drops[_dropId].collectionIds.length; i++) {
            require(
                _legendCollection.getCollectionCreator(
                    _drops[_dropId].collectionIds[i]
                ) ==
                    msg.sender &&
                    (_accessControl.isWriter(msg.sender) ||
                        _accessControl.isAdmin(msg.sender)),
                "LegendDrop: Only the owner of a collection can add it to a drop"
            );
        }

        uint256[] memory collectionIds = _drops[_dropId].collectionIds;
        for (uint256 i = 0; i < collectionIds.length; i++) {
            _collectionIdToDrop[collectionIds[i]] = 0;
        }
        delete _drops[_dropId];

        emit DropDeleted(_dropId, msg.sender);
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

    function getCollectionsInDrop(uint256 _dropId)
        public
        view
        returns (uint256[] memory)
    {
        return _drops[_dropId].collectionIds;
    }

    function getCollectionIdToDrop(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _collectionIdToDrop[_collectionId];
    }

    function getDropURI(uint256 _dropId) public view returns (string memory) {
        return _drops[_dropId].dropURI;
    }

    function getDropCreator(uint256 _dropId) public view returns (address) {
        return _drops[_dropId].creator;
    }

    function getDropTimestamp(uint256 _dropId) public view returns (uint256) {
        return _drops[_dropId].timestamp;
    }

    function setDropURI(uint256 _dropId, string memory _dropURI) external {
        for (uint256 i = 0; i < _drops[_dropId].collectionIds.length; i++) {
            require(
                _legendCollection.getCollectionCreator(
                    _drops[_dropId].collectionIds[i]
                ) ==
                    msg.sender &&
                    (_accessControl.isWriter(msg.sender) ||
                        _accessControl.isAdmin(msg.sender)),
                "LegendDrop: Only the owner of a drop can edit a drop"
            );
        }
        _drops[_dropId].dropURI = _dropURI;
        emit DropURIUpdated(_dropId, _dropURI);
    }

    function getLegendCollectionContract() public view returns (address) {
        return address(_legendCollection);
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getDropSupply() public view returns (uint256) {
        return _dropSupply;
    }
}
