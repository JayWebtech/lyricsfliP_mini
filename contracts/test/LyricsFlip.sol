// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LyricsFlip.sol";

contract GamePlayTest is Test {
    GamePlay gamePlay;
    address owner;
    address addr1;
    address addr2;
    address addr3;
    string username1 = "player1";
    string username2 = "player2";
    string username3 = "player3";

    event UserRegistered(string username, address indexed walletAddress);
    event GamePlayed(string username, address indexed player, uint256 totalPlayCount, uint256 playerPlayCount);
    event NFTRewarded(address indexed player, uint256 tokenId);

    function setUp() public {
        owner = address(this);
        addr1 = address(0x1);
        addr2 = address(0x2);
        addr3 = address(0x3);
        gamePlay = new GamePlay();
    }

    function testDeployment() public {
        assertEq(gamePlay.owner(), owner, "Owner should be set correctly");
        assertEq(gamePlay.name(), "GamePlayNFT", "NFT name should be correct");
        assertEq(gamePlay.symbol(), "GPNFT", "NFT symbol should be correct");
        assertEq(gamePlay.getTotalPlayCount(), 0, "Initial total play count should be 0");
    }

    function testRegisterUsername() public {
        vm.prank(addr1);
        vm.expectEmit(true, true, false, true);
        emit UserRegistered(username1, addr1);
        gamePlay.registerUsername(username1, addr1);

        assertEq(gamePlay.usernameToAddress(username1), addr1, "Username should map to correct address");
        assertTrue(gamePlay.usernameTaken(username1), "Username should be marked as taken");
        string[] memory usernames = gamePlay.getUsernames();
        assertEq(usernames.length, 1, "Usernames array should have one entry");
        assertEq(usernames[0], username1, "Username should be stored correctly");
    }

    function testFailRegisterDuplicateUsername() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.prank(addr2);
        vm.expectRevert("Username already taken");
        gamePlay.registerUsername(username1, addr2);
    }

    function testFailRegisterZeroAddress() public {
        vm.prank(addr1);
        vm.expectRevert("Invalid wallet address");
        gamePlay.registerUsername(username1, address(0));
    }

    function testPlayGame() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);

        vm.prank(addr1);
        vm.expectEmit(true, true, false, true);
        emit GamePlayed(username1, addr1, 1, 1);
        gamePlay.playGame(username1);

        assertEq(gamePlay.getTotalPlayCount(), 1, "Total play count should be 1");
        assertEq(gamePlay.getPlayerPlayCount(username1), 1, "Player play count should be 1");
        address[] memory players = gamePlay.getPlayers();
        assertEq(players.length, 1, "Players array should have one entry");
        assertEq(players[0], addr1, "Player address should be correct");
    }

    function testFailPlayUnregisteredUsername() public {
        vm.prank(addr1);
        vm.expectRevert("Username not registered");
        gamePlay.playGame(username1);
    }

    function testFailPlayWrongWallet() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.prank(addr2);
        vm.expectRevert("Caller must be the registered wallet");
        gamePlay.playGame(username1);
    }

    function testMultiplePlays() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.prank(addr1);
        gamePlay.playGame(username1);
        vm.prank(addr1);
        gamePlay.playGame(username1);

        assertEq(gamePlay.getTotalPlayCount(), 2, "Total play count should be 2");
        assertEq(gamePlay.getPlayerPlayCount(username1), 2, "Player play count should be 2");
        address[] memory players = gamePlay.getPlayers();
        assertEq(players.length, 1, "Players array should have one entry");
    }

    function testMintNFT() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.prank(addr1);
        gamePlay.playGame(username1);

        vm.expectEmit(true, true, false, true);
        emit NFTRewarded(addr1, 1);
        gamePlay.mintNFT(addr1);

        assertEq(gamePlay.ownerOf(1), addr1, "NFT should be owned by addr1");
        assertTrue(gamePlay.hasReceivedNFT(addr1), "Player should have received NFT");
    }

    function testFailMintNFTNonOwner() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.prank(addr1);
        gamePlay.playGame(username1);

        vm.prank(addr2);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, addr2));
        gamePlay.mintNFT(addr1);
    }

    function testFailMintNFTNoPlays() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.expectRevert("Player has not played");
        gamePlay.mintNFT(addr1);
    }

    function testFailMintNFTAlreadyReceived() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.prank(addr1);
        gamePlay.playGame(username1);
        gamePlay.mintNFT(addr1);
        vm.expectRevert("Player already received NFT");
        gamePlay.mintNFT(addr1);
    }

    function testLeaderboard() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.prank(addr2);
        gamePlay.registerUsername(username2, addr2);
        vm.prank(addr3);
        gamePlay.registerUsername(username3, addr3);
        vm.prank(addr1);
        gamePlay.playGame(username1);
        vm.prank(addr1);
        gamePlay.playGame(username1);
        vm.prank(addr2);
        gamePlay.playGame(username2);

        (string[] memory usernames, uint256[] memory playCounts) = gamePlay.getLeaderboard();
        assertEq(usernames.length, 3, "Leaderboard should have 3 usernames");
        assertEq(playCounts.length, 3, "Leaderboard should have 3 play counts");
        assertEq(usernames[0], username1, "First username should be player1");
        assertEq(usernames[1], username2, "Second username should be player2");
        assertEq(usernames[2], username3, "Third username should be player3");
        assertEq(playCounts[0], 2, "player1 should have 2 plays");
        assertEq(playCounts[1], 1, "player2 should have 1 play");
        assertEq(playCounts[2], 0, "player3 should have 0 plays");
    }

    function testLeaderboardPaginated() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.prank(addr2);
        gamePlay.registerUsername(username2, addr2);
        vm.prank(addr3);
        gamePlay.registerUsername(username3, addr3);
        vm.prank(addr1);
        gamePlay.playGame(username1);
        vm.prank(addr2);
        gamePlay.playGame(username2);

        (string[] memory usernames, uint256[] memory playCounts) = gamePlay.getLeaderboardPaginated(1, 2);
        assertEq(usernames.length, 2, "Paginated leaderboard should have 2 usernames");
        assertEq(playCounts.length, 2, "Paginated leaderboard should have 2 play counts");
        assertEq(usernames[0], username2, "First username should be player2");
        assertEq(usernames[1], username3, "Second username should be player3");
        assertEq(playCounts[0], 1, "player2 should have 1 play");
        assertEq(playCounts[1], 0, "player3 should have 0 plays");
    }

    function testFailInvalidPagination() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.expectRevert("Invalid start index");
        gamePlay.getLeaderboardPaginated(1, 1);
    }

    function testResetCounter() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);
        vm.prank(addr2);
        gamePlay.registerUsername(username2, addr2);
        vm.prank(addr1);
        gamePlay.playGame(username1);
        vm.prank(addr2);
        gamePlay.playGame(username2);

        gamePlay.resetCounter();
        assertEq(gamePlay.getTotalPlayCount(), 0, "Total play count should be reset");
        assertEq(gamePlay.getPlayerPlayCount(username1), 0, "Player1 play count should be reset");
        assertEq(gamePlay.getPlayerPlayCount(username2), 0, "Player2 play count should be reset");
        assertEq(gamePlay.getPlayers().length, 0, "Players array should be empty");
        assertEq(gamePlay.getUsernames().length, 2, "Usernames should be preserved");
    }

    function testFailResetCounterNonOwner() public {
        vm.prank(addr1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, addr1));
        gamePlay.resetCounter();
    }

    function testViewFunctions() public {
        vm.prank(addr1);
        gamePlay.registerUsername(username1, addr1);

        assertEq(gamePlay.getWalletAddress(username1), addr1, "Should return correct wallet address");
        assertEq(gamePlay.getWalletAddress("nonexistent"), address(0), "Should return zero address for unregistered username");

        vm.prank(addr1);
        gamePlay.playGame(username1);
        address[] memory players = gamePlay.getPlayers();
        assertEq(players.length, 1, "Players array should have one entry");
        assertEq(players[0], addr1, "Player address should be correct");

        string[] memory usernames = gamePlay.getUsernames();
        assertEq(usernames.length, 1, "Usernames array should have one entry");
        assertEq(usernames[0], username1, "Username should be correct");
    }
}