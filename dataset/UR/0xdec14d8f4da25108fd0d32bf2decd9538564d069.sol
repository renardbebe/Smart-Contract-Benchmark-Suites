 

pragma solidity ^0.4.18;

contract CryptoVideoGames {

    address contractCreator = 0xC15d9f97aC926a6A29A681f5c19e2b56fd208f00;
    address devFeeAddress = 0xC15d9f97aC926a6A29A681f5c19e2b56fd208f00;

    struct VideoGame {
        string videoGameName;
        address ownerAddress;
        uint256 currentPrice;
    }
    VideoGame[] videoGames;

    modifier onlyContractCreator() {
        require (msg.sender == contractCreator);
        _;
    }

    bool isPaused;
    
    
     
    function pauseGame() public onlyContractCreator {
        isPaused = true;
    }
    function unPauseGame() public onlyContractCreator {
        isPaused = false;
    }
    function GetGamestatus() public view returns(bool) {
       return(isPaused);
    }

     
    function purchaseVideoGame(uint _videoGameId) public payable {
        require(msg.value == videoGames[_videoGameId].currentPrice);
        require(isPaused == false);

         
        uint256 devFee = (msg.value / 10);

         
        uint256 commissionOwner = msg.value - devFee;  
        videoGames[_videoGameId].ownerAddress.transfer(commissionOwner);

         
        devFeeAddress.transfer(devFee);  

         
        videoGames[_videoGameId].ownerAddress = msg.sender;
        videoGames[_videoGameId].currentPrice = mul(videoGames[_videoGameId].currentPrice, 2);
    }
    
     
    function modifyCurrentVideoGamePrice(uint _videoGameId, uint256 _newPrice) public {
        require(_newPrice > 0);
        require(videoGames[_videoGameId].ownerAddress == msg.sender);
        require(_newPrice < videoGames[_videoGameId].currentPrice);
        videoGames[_videoGameId].currentPrice = _newPrice;
    }
    
     
    function getVideoGameDetails(uint _videoGameId) public view returns (
        string videoGameName,
        address ownerAddress,
        uint256 currentPrice
    ) {
        VideoGame memory _videoGame = videoGames[_videoGameId];

        videoGameName = _videoGame.videoGameName;
        ownerAddress = _videoGame.ownerAddress;
        currentPrice = _videoGame.currentPrice;
    }
    
     
    function getVideoGameCurrentPrice(uint _videoGameId) public view returns(uint256) {
        return(videoGames[_videoGameId].currentPrice);
    }
    
     
    function getVideoGameOwner(uint _videoGameId) public view returns(address) {
        return(videoGames[_videoGameId].ownerAddress);
    }
    
    
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
    
     
    function addVideoGame(string videoGameName, address ownerAddress, uint256 currentPrice) public onlyContractCreator {
        videoGames.push(VideoGame(videoGameName,ownerAddress,currentPrice));
    }
    
}