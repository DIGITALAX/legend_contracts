// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./LegendKeeper.sol";
import "./LegendAccessControl.sol";
import "./LegendFactory.sol";
import "./GlobalLegendAccessControl.sol";

library DynamicNFTLibrary {
    struct ConstructorArgs {
        address lensHubProxyAddress;
        address legendFactoryAddress;
        string[] URIArrayValue;
        string grantNameValue;
        uint256 editionAmountValue;
    }
}

contract LegendDynamicNFT is ERC721 {
    using Counters for Counters.Counter;
    uint256 private _editionAmount;
    uint256 private _currentCounter;
    uint256 private _maxSupply;
    string[] private _URIArray;
    string private _myBaseURI;
    string private _grantName;
    address private _deployerAddress;

    mapping(address => bool) private _collectorClaimedNFT;
    mapping(address => uint256) private _collectorMapping;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => mapping(address => bool)) private _collectorToPubId;

    Counters.Counter private _tokenIdCounter;
    ICollectNFT private _collectNFT;
    ILensHubProxy private _lensHubProxy;
    LegendKeeper private _legendKeeper;
    LegendAccessControl private _legendAccessControl;
    LegendFactory private _legendFactory;

    event TokenURIUpdated(
        uint256 indexed tokenId,
        string newURI,
        address updater
    );

    modifier onlyFactory() {
        require(
            msg.sender == address(_legendFactory),
            "LegendDynamicNFT: Only the factory can set the keeper address"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            _legendAccessControl.isAdmin(msg.sender),
            "LegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyKeeper() {
        require(
            msg.sender == address(_legendKeeper),
            "LegendDynamicNFT: Only the Keeper Contract can perform this action"
        );
        _;
    }

    modifier onlyCollector() {
        require(
            _collectNFT.balanceOf(msg.sender) > 0,
            "LegendDynamicNFT: Only Publication Collectors can perform this action"
        );
        _;
    }

    constructor(
        DynamicNFTLibrary.ConstructorArgs memory args,
        address _legendAccessControlValue,
        address _legendFactoryValue,
        address _deployerAddressValue
    ) ERC721("LegendDynamicNFT", "LDNFT") {
        _editionAmount = args.editionAmountValue;
        _URIArray = args.URIArrayValue;
        _currentCounter = 0;
        _deployerAddress = _deployerAddressValue;
        _legendAccessControl = LegendAccessControl(_legendAccessControlValue);
        _legendFactory = LegendFactory(_legendFactoryValue);
        _lensHubProxy = ILensHubProxy(args.lensHubProxyAddress);
        _myBaseURI = _URIArray[0];
        _grantName = args.grantNameValue;
        _maxSupply = _editionAmount;
    }

    function safeMint(address _to) external onlyCollector {
        require(
            !_collectorClaimedNFT[msg.sender],
            "LegendDynamicNFT: Only 1 NFT can be claimed per unique collector."
        );

        require(
            _tokenIdCounter.current() < _maxSupply,
            "LegendDynamicNFT: Cannot mint above the max supply."
        );

        uint256 _tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(_to, _tokenId);

        _collectorClaimedNFT[msg.sender] = true;
        _collectorToPubId[_legendKeeper.getPostId()][msg.sender] = true;
        _collectorMapping[msg.sender] = _lensHubProxy.defaultProfile(
            _deployerAddress
        );
    }

    function updateMetadata(uint256 _totalAmountOfCollects)
        external
        onlyKeeper
    {
        if (_totalAmountOfCollects > _editionAmount) return;

        if (_totalAmountOfCollects == _editionAmount) {
            _legendFactory.setGrantStatus(
                _deployerAddress,
                "ended",
                _grantName
            );
        }

        _currentCounter += _totalAmountOfCollects;

        // update new uri for all tokenids
        _myBaseURI = _URIArray[_currentCounter];
    }

    function _burn(uint256 _tokenId) internal override {
        super._burn(_tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _myBaseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _myBaseURI;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function setLegendKeeperAddress(address _legendKeeperAddress)
        external
        onlyFactory
    {
        _legendKeeper = LegendKeeper(_legendKeeperAddress);
    }

    function setCollectNFTAddress(address _collectNFTAddress)
        external
        onlyKeeper
    {
        require(address(_collectNFT) == address(0));
        _collectNFT = ICollectNFT(_collectNFTAddress);
    }

    function getEditionAmount() public view returns (uint256) {
        return _editionAmount;
    }

    function getCurrentCounter() public view returns (uint256) {
        return _currentCounter;
    }

    function getCollectorClaimedNFT(address _collectorAddress)
        public
        view
        returns (bool)
    {
        return _collectorClaimedNFT[_collectorAddress];
    }

    function getCollectorMapping(address _collectorAddress)
        public
        view
        returns (uint256)
    {
        return _collectorMapping[_collectorAddress];
    }

    function getCollectorPubId(address _address) public view returns (bool) {
        return _collectorToPubId[_legendKeeper.getPostId()][_address];
    }

    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function getGrantName() public view returns (string memory) {
        return _grantName;
    }

    function getDeployerAddress() public view returns (address) {
        return _deployerAddress;
    }

    function getLegendKeeperAddress() public view returns (address) {
        return address(_legendKeeper);
    }

    function getLegendAccessControlAddress() public view returns (address) {
        return address(_legendAccessControl);
    }

    function getCollectNFTAddress() public view returns (address) {
        return address(_collectNFT);
    }
}
