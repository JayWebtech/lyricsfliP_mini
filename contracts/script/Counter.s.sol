// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {GamePlay} from "../src/LyricsFlip.sol";

contract GamePlayScript is Script {
    GamePlay public gamePlay;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        gamePlay = new GamePlay();

        vm.stopBroadcast();
    }
}