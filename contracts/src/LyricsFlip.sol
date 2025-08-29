// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GamePlay is ERC721, Ownable, EIP712 {
    // State variable to store the total number of times the game has been played
    uint256 public totalPlayCount;

    // Mapping to track the number of plays per wallet address
    mapping(address => uint256) public playerPlayCount;

    // Mapping to associate username with wallet address
    mapping(string => address) public usernameToAddress;

    // Mapping to ensure usernames are unique
    mapping(string => bool) public usernameTaken;

    // Array to store unique player wallet addresses
    address[] public players;

    // Array to store usernames
    string[] public usernames;

    // NFT token counter
    uint256 private _tokenIdCounter;

    // Mapping to track which players have received NFTs
    mapping(address => bool) public hasReceivedNFT;

    // Mapping to track nonces for meta-transactions
    mapping(address => uint256) public nonces;

    // Event emitted when a user registers
    event UserRegistered(string username, address indexed walletAddress);

    // Event emitted when the game is played
    event GamePlayed(string username, address indexed player, uint256 totalPlayCount, uint256 playerPlayCount);

    // Event emitted when an NFT is minted
    event NFTRewarded(address indexed player, uint256 tokenId);

    // EIP-712 type hashes
    bytes32 private constant REGISTER_TYPEHASH = keccak256("RegisterUsername(string username,address walletAddress,uint256 nonce)");
    bytes32 private constant PLAY_TYPEHASH = keccak256("PlayGame(string username,uint256 nonce)");

    // Constructor to initialize ERC721, Ownable, and EIP712
    constructor() ERC721("GamePlayNFT", "GPNFT") Ownable(msg.sender) EIP712("GamePlay", "1") {
        _tokenIdCounter = 1; // Start token IDs at 1
    }

    // Function to register a username with meta-transaction support
    function registerUsername(
        string calldata _username,
        address _walletAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Verify the signature
        bytes32 structHash = keccak256(abi.encode(REGISTER_TYPEHASH, keccak256(bytes(_username)), _walletAddress, nonces[_walletAddress]));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, v, r, s);
        require(signer == _walletAddress, "Invalid signature");
        require(!usernameTaken[_username], "Username already taken");
        require(usernameToAddress[_username] == address(0), "Username already registered");
        require(_walletAddress != address(0), "Invalid wallet address");

        // Increment nonce to prevent replay
        nonces[_walletAddress]++;

        // Register the username
        usernameTaken[_username] = true;
        usernameToAddress[_username] = _walletAddress;
        usernames.push(_username);

        emit UserRegistered(_username, _walletAddress);
    }

    // Function to play the game with meta-transaction support
    function playGame(
        string calldata _username,
        address _playerAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Verify the signature
        bytes32 structHash = keccak256(abi.encode(PLAY_TYPEHASH, keccak256(bytes(_username)), nonces[_playerAddress]));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, v, r, s);
        require(signer == _playerAddress, "Invalid signature");
        require(usernameToAddress[_username] == _playerAddress, "Username not registered to this address");

        // Increment nonce to prevent replay
        nonces[_playerAddress]++;

        // Update play counts
        totalPlayCount++;
        if (playerPlayCount[_playerAddress] == 0) {
            players.push(_playerAddress);
        }
        playerPlayCount[_playerAddress]++;

        emit GamePlayed(_username, _playerAddress, totalPlayCount, playerPlayCount[_playerAddress]);
    }

    // Function to mint an NFT to a top player (owner only)
    function mintNFT(address _player) external onlyOwner {
        require(playerPlayCount[_player] > 0, "Player has not played");
        require(!hasReceivedNFT[_player], "Player already received NFT");

        uint256 tokenId = _tokenIdCounter++;
        _safeMint(_player, tokenId);
        hasReceivedNFT[_player] = true;

        emit NFTRewarded(_player, tokenId);
    }

    // Function to get the total play count
    function getTotalPlayCount() external view returns (uint256) {
        return totalPlayCount;
    }

    // Function to get the play count for a specific player by username
    function getPlayerPlayCount(string calldata _username) external view returns (uint256) {
        address playerAddress = usernameToAddress[_username];
        require(playerAddress != address(0), "Username not registered");
        return playerPlayCount[playerAddress];
    }

    // Function to get the wallet address for a username
    function getWalletAddress(string calldata _username) external view returns (address) {
        return usernameToAddress[_username];
    }

    // Function to get the list of all players
    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    // Function to get the list of all usernames
    function getUsernames() external view returns (string[] memory) {
        return usernames;
    }

    // Function to get paginated leaderboard data
    function getLeaderboardPaginated(uint256 _start, uint256 _limit)
        external
        view
        returns (string[] memory, uint256[] memory)
    {
        require(_start < usernames.length, "Invalid start index");
        uint256 end = _start + _limit > usernames.length ? usernames.length : _start + _limit;
        string[] memory paginatedUsernames = new string[](end - _start);
        uint256[] memory paginatedPlayCounts = new uint256[](end - _start);

        for (uint256 i = _start; i < end; i++) {
            paginatedUsernames[i - _start] = usernames[i];
            paginatedPlayCounts[i - _start] = playerPlayCount[usernameToAddress[usernames[i]]];
        }
        return (paginatedUsernames, paginatedPlayCounts);
    }

    // Function to get the original leaderboard data (for backward compatibility)
    function getLeaderboard() external view returns (string[] memory, uint256[] memory) {
        uint256[] memory playCounts = new uint256[](usernames.length);
        for (uint256 i = 0; i < usernames.length; i++) {
            playCounts[i] = playerPlayCount[usernameToAddress[usernames[i]]];
        }
        return (usernames, playCounts);
    }

    // Function to reset the counter (owner only)
    function resetCounter() external onlyOwner {
        totalPlayCount = 0;
        for (uint256 i = 0; i < players.length; i++) {
            playerPlayCount[players[i]] = 0;
        }
        delete players;
        // Usernames and their mappings are preserved to maintain user accounts
    }
}