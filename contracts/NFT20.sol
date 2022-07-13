// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Fungible Non-Fungible Token
 * @author Beau Williams (@beauwilliams)
 * @dev Smart contract for NFTCOIN a.k.a NFT20
 */
contract NFTCOIN is ERC721, ERC721Enumerable, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    uint256 constant public TOTAL_SUPPLY = 100000000000000000000000000;
    uint256 constant public TOTAL_WALLETS = 1000000000000;
    mapping(uint256 => uint256) public walletBalance;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("NFT20", "N20") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
    }

    error NotConsumerOwner();
    error InsufficientFunds();
    error SenderIsReceiver();
    error AccountNotExist();

    function getFidelity() public pure returns (uint256 fidelity) {
        return TOTAL_SUPPLY/TOTAL_WALLETS;
    }

    function getConsumerBalance(uint256 tokenId) public view returns (uint256 balance) {
        return walletBalance[tokenId];
    }

    function sendBalance(uint256 consumerFrom, uint256 consumerTo, uint256 amount) public returns (bool success) {
    if (consumerFrom == consumerTo)
        revert SenderIsReceiver();
    if (consumerFrom > _tokenIdCounter.current())
        revert AccountNotExist();
    if (ownerOf(consumerFrom) != msg.sender)
        revert NotConsumerOwner();
    if (amount > walletBalance[consumerFrom])
        revert InsufficientFunds();
    walletBalance[consumerFrom]-= amount;
    walletBalance[consumerTo] += amount;
    return true;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.coin/";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mintWallet(address to) public onlyRole(ISSUER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        walletBalance[tokenId] = getFidelity();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }



    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

