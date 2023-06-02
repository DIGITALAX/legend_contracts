// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./LegendCollection.sol";
import "./LegendMarket.sol";
import "./GlobalLegendAccessControl.sol";
import "./LegendNFT.sol";

contract LegendEscrow is ERC721Holder {
    GlobalLegendAccessControl private _accessControl;
    LegendCollection private _legendCollection;
    LegendMarket private _legendMarketplace;
    LegendNFT private _legendNFT;
    string public symbol;
    string public name;

    mapping(uint256 => bool) private _deposited;

    event LegendMarketplaceUpdated(
        address indexed oldLegendMarketplace,
        address indexed newLegendMarketplace,
        address updater
    );
    event LegendCollectionUpdated(
        address indexed oldLegendCollection,
        address indexed newLegendCollection,
        address updater
    );
    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );
    event LegendNFTUpdated(
        address indexed oldLegendNFT,
        address indexed newLegendNFT,
        address updater
    );

    constructor(
        address _legendCollectionContract,
        address _legendMarketplaceContract,
        address _accessControlContract,
        address _legendNFTContract,
        string memory _symbol,
        string memory _name
    ) {
        _legendCollection = LegendCollection(_legendCollectionContract);
        _legendMarketplace = LegendMarket(_legendMarketplaceContract);
        _accessControl = GlobalLegendAccessControl(_accessControlContract);
        _legendNFT = LegendNFT(_legendNFTContract);
        symbol = _symbol;
        name = _name;
    }

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyDepositer() {
        require(
            msg.sender == address(_legendCollection) ||
                msg.sender == address(_legendNFT),
            "LegendEscrow: Only the Legend Collection or NFT contract can call this function"
        );
        _;
    }

    modifier onlyReleaser(bool _isBurn, uint256 _tokenId) {
        require(
            msg.sender == address(_legendMarketplace) ||
                msg.sender == address(_legendCollection) ||
                msg.sender == address(_legendNFT),
            "LegendEscrow: Only the Legend Marketplace contract can call this function"
        );
        if (_isBurn) {
            require(
                _legendNFT.getTokenCreator(_tokenId) == msg.sender ||
                    address(_legendCollection) == msg.sender,
                "LegendEscrow: Only the creator of the token can transfer it to the burn address"
            );
        }
        _;
    }

    function deposit(uint256 _tokenId, bool _bool) external onlyDepositer {
        require(
            _legendNFT.ownerOf(_tokenId) == address(this),
            "LegendEscrow: Token must be owned by escrow contract or Owner"
        );
        _deposited[_tokenId] = _bool;
    }

    function release(
        uint256 _tokenId,
        bool _isBurn,
        address _to
    ) external onlyReleaser(_isBurn, _tokenId) {
        require(_deposited[_tokenId], "LegendEscrow: Token must be in escrow");
        _deposited[_tokenId] = false;
        if (_isBurn) {
            _legendNFT.burn(_tokenId);
        } else {
            _legendNFT.safeTransferFrom(address(this), _to, _tokenId);
        }
    }

    function updateLegendMarketplace(address _newLegendMarketplace)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendMarketplace);
        _legendMarketplace = LegendMarket(_newLegendMarketplace);
        emit LegendMarketplaceUpdated(
            oldAddress,
            _newLegendMarketplace,
            msg.sender
        );
    }

    function updateLegendCollection(address _newLegendCollection)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendCollection);
        _legendCollection = LegendCollection(_newLegendCollection);
        emit LegendCollectionUpdated(
            oldAddress,
            _newLegendCollection,
            msg.sender
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

    function updateLegendNFT(address _newLegendNFTAddress) external onlyAdmin {
        address oldAddress = address(_legendNFT);
        _legendNFT = LegendNFT(_newLegendNFTAddress);
        emit LegendNFTUpdated(oldAddress, _newLegendNFTAddress, msg.sender);
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getLegendNFTContract() public view returns (address) {
        return address(_legendNFT);
    }

    function getLegendMarketContract() public view returns (address) {
        return address(_legendMarketplace);
    }

    function getLegendCollectionContract() public view returns (address) {
        return address(_legendCollection);
    }
}
