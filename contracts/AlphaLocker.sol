//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract AlphaLocker is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
   //Declare Events
    event Locked(address indexed _owner, uint256 _tokenId, uint256 _timeStamp);
    event Unlocked(address indexed _owner, uint256 _tokenId, uint256 _timeStamp);

    struct Locker {
        uint256 state;  // 0 -> Unlocked, 1 -> Locked
        uint256 tokenNumber;
        address lockerOwner;
    }

    // Mapping NFT to locker
    mapping (uint256 => Locker) public nftLocker;

    IERC721 public nftTokenAddress;

    bool public lockupWindow = false;

    function updateNftAddress(IERC721 _token)public onlyOwner{
        nftTokenAddress = IERC721(_token);
    }
    
    function toggleLockupWindow() external onlyOwner {
        lockupWindow = !lockupWindow;
    }
    
    function lock(uint256 _tokenId) external {
        require(nftTokenAddress.ownerOf(_tokenId)==msg.sender, "You are not Owner of the NFT");
        Locker storage locker = nftLocker[_tokenId];
        require(locker.state == 0, "This NFT is Locked");

        nftTokenAddress.safeTransferFrom(msg.sender, address(this), _tokenId);
        locker.lockerOwner = msg.sender;
        locker.state = 1;
        locker.tokenNumber = _tokenId;

        // Emit Locked!
        emit Locked(msg.sender, _tokenId, block.timestamp); 
    }

    function unLockNFT(uint256 _tokenId) external {
        Locker storage locker = nftLocker[_tokenId];
        require(locker.state == 1, "This NFT is not Locked");
        require(locker.lockerOwner==msg.sender, "You are not owner of the Token");
        require(nftTokenAddress.ownerOf(_tokenId)==address(this), "NFT is not locked in this contract");
        
        nftTokenAddress.safeTransferFrom(address(this), locker.lockerOwner, _tokenId);
        locker.state = 0;
        
        // Emit Unlocked!
        emit Unlocked(locker.lockerOwner, _tokenId, block.timestamp); 
    }

}