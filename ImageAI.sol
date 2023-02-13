// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ImageAI is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    uint public minted =0;
    uint256 public LATEST_CLAIMED_ID;
    uint public claimPrice = 10000000000000000 wei; //0.01 Ethers

    mapping(uint256 => bool) public claimedTokens;

    bool public canClaim = false;    

    event Claim(uint256 indexed _id);
    
    function flipState() external onlyOwner {
        canClaim = !canClaim;
    }

    function getNumMinted() public view returns(uint){
        return minted;
    }

    /// @notice allows external users to claim NFTs by paying a fee
    // n - number of NFTs to claim at once 
    function claim(uint n) public payable nonReentrant{
        require(canClaim, "claim has not started yet.");
        require(n>0);  
        require(n<=50); //cannot claim more than 50 at once

        uint total_cost = claimPrice * n;
        require(msg.value >= total_cost);
        uint excess = msg.value - total_cost; 
        payable(address(this)).transfer(total_cost); 
        
        //after recieving fees, mint NFTs;
        for (uint i=0; i<n; i++){
            uint nextId = minted;
            minted += 1;
            _safeMint(_msgSender(), nextId); 
            emit Claim(nextId);
        }
        LATEST_CLAIMED_ID = minted - 1;
        payable(_msgSender()).transfer(excess);     
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    string base_uri = "metadata.voicegpt.us/tokens/";

    function set_base_uri(string memory new_base_uri) public onlyOwner{
        base_uri = new_base_uri;
    }
    
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty 
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return base_uri;
    }

    receive() external payable{}
    fallback() external payable {}
    function withdrawBalance() external onlyOwner  {
         uint256 balance = address(this).balance;
         payable(_msgSender()).transfer(balance);
     }
   function getBalance() external view returns(uint){
         uint256 balance = address(this).balance;
         return balance;
    }
    
    constructor() ERC721("ImageCreateByAI", "IAI") Ownable() {}
}