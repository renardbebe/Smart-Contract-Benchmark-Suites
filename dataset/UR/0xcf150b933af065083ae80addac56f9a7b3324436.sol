 

pragma solidity ^0.4.18;

 

contract PlayCryptoGaming {

    address contractOwnerAddress = 0x46d9112533ef677059c430E515775e358888e38b;
    uint256 priceContract = 26000000000000000000;


    modifier onlyOwner() {
        require (msg.sender == contractOwnerAddress);
        _;
    }
    
    struct CryptoGamer {
        string name;
        address ownerAddress;
        uint256 curPrice;
    }
    CryptoGamer[] cryptoGamers;

    bool cryptoGamersAreInitiated;
    bool isPaused;
    
     
    function pauseGame() public onlyOwner {
        isPaused = true;
    }
    function unPauseGame() public onlyOwner {
        isPaused = false;
    }
    function GetIsPaused() public view returns(bool) {
       return(isPaused);
    }

     
    function purchaseCryptoGamer(uint _cryptoGamerId) public payable {
        require(msg.value == cryptoGamers[_cryptoGamerId].curPrice);
        require(isPaused == false);

         
        uint256 commission5percent = ((msg.value / 10)/2);
        
         
        address leastExpensiveCryptoGamerOwner = cryptoGamers[getLeastExpensiveCryptoGamer()].ownerAddress;
        address mostExpensiveCryptoGamerOwner = cryptoGamers[getMostExpensiveCryptoGamer()].ownerAddress;
        
         
        if(leastExpensiveCryptoGamerOwner == address(this)) { 
            leastExpensiveCryptoGamerOwner = contractOwnerAddress; 
        }
        if(mostExpensiveCryptoGamerOwner == address(this)) { 
            mostExpensiveCryptoGamerOwner = contractOwnerAddress; 
        }
        
        leastExpensiveCryptoGamerOwner.transfer(commission5percent);  
        mostExpensiveCryptoGamerOwner.transfer(commission5percent);  

         
        uint256 commissionOwner = msg.value - (commission5percent * 3);  
        
         
        if(cryptoGamers[_cryptoGamerId].ownerAddress == address(this)) {
            contractOwnerAddress.transfer(commissionOwner);

        } else {
             
            cryptoGamers[_cryptoGamerId].ownerAddress.transfer(commissionOwner);
        }
        

         
        contractOwnerAddress.transfer(commission5percent);  

         
        cryptoGamers[_cryptoGamerId].ownerAddress = msg.sender;
        cryptoGamers[_cryptoGamerId].curPrice = cryptoGamers[_cryptoGamerId].curPrice + (cryptoGamers[_cryptoGamerId].curPrice / 2);
    }

     
    function purchaseContract() public payable {
        require(msg.value == priceContract);
        
         
        uint256 commission5percent = ((msg.value / 10)/2);
        
         
        address leastExpensiveCryptoGamerOwner = cryptoGamers[getLeastExpensiveCryptoGamer()].ownerAddress;
        address mostExpensiveCryptoGamerOwner = cryptoGamers[getMostExpensiveCryptoGamer()].ownerAddress;
        
         
        if(leastExpensiveCryptoGamerOwner == address(this)) { 
            leastExpensiveCryptoGamerOwner = contractOwnerAddress; 
        }
        if(mostExpensiveCryptoGamerOwner == address(this)) { 
            mostExpensiveCryptoGamerOwner = contractOwnerAddress; 
        }
        
         
        leastExpensiveCryptoGamerOwner.transfer(commission5percent);  
        mostExpensiveCryptoGamerOwner.transfer(commission5percent);  

         
        uint256 commissionOwner = msg.value - (commission5percent * 2);  
        
        contractOwnerAddress.transfer(commissionOwner);
        contractOwnerAddress = msg.sender;
    }

    function getPriceContract() public view returns(uint) {
        return(priceContract);
    }

     
    function updatePriceContract(uint256 _newPrice) public onlyOwner {
        priceContract = _newPrice;
    }

     
    function getContractOwnerAddress() public view returns(address) {
        return(contractOwnerAddress);
    }

     
    function updateCryptoGamerPrice(uint _cryptoGamerId, uint256 _newPrice) public {
        require(_newPrice > 0);
        require(cryptoGamers[_cryptoGamerId].ownerAddress == msg.sender);
        require(_newPrice < cryptoGamers[_cryptoGamerId].curPrice);
        cryptoGamers[_cryptoGamerId].curPrice = _newPrice;
    }
    
     
    function getCryptoGamer(uint _cryptoGamerId) public view returns (
        string name,
        address ownerAddress,
        uint256 curPrice
    ) {
        CryptoGamer storage _cryptoGamer = cryptoGamers[_cryptoGamerId];

        name = _cryptoGamer.name;
        ownerAddress = _cryptoGamer.ownerAddress;
        curPrice = _cryptoGamer.curPrice;
    }
    
     
    function getLeastExpensiveCryptoGamer() public view returns(uint) {
        uint _leastExpensiveGamerId = 0;
        uint256 _leastExpensiveGamerPrice = 9999000000000000000000;

         
        for (uint8 i = 0; i < cryptoGamers.length; i++) {
            if(cryptoGamers[i].curPrice < _leastExpensiveGamerPrice) {
                _leastExpensiveGamerPrice = cryptoGamers[i].curPrice;
                _leastExpensiveGamerId = i;
            }
        }
        return(_leastExpensiveGamerId);
    }

     
    function getMostExpensiveCryptoGamer() public view returns(uint) {
        uint _mostExpensiveGamerId = 0;
        uint256 _mostExpensiveGamerPrice = 9999000000000000000000;

         
        for (uint8 i = 0; i < cryptoGamers.length; i++) {
            if(cryptoGamers[i].curPrice > _mostExpensiveGamerPrice) {
                _mostExpensiveGamerPrice = cryptoGamers[i].curPrice;
                _mostExpensiveGamerId = i;
            }
        }
        return(_mostExpensiveGamerId);
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
    
     
    function createCryptoGamer(string _cryptoGamerName, uint256 _cryptoGamerPrice) public onlyOwner {
        cryptoGamers.push(CryptoGamer(_cryptoGamerName, address(this), _cryptoGamerPrice));
    }
    
     
    function InitiateCryptoGamers() public onlyOwner {
        require(cryptoGamersAreInitiated == false);
        createCryptoGamer("Phil", 450000000000000000); 
        createCryptoGamer("Carlini8", 310000000000000000); 
        createCryptoGamer("Ferocious", 250000000000000000); 
        createCryptoGamer("Pranked", 224000000000000000); 
        createCryptoGamer("SwagDaPanda", 181000000000000000); 
        createCryptoGamer("Slush", 141000000000000000); 
        createCryptoGamer("Acapuck", 107000000000000000); 
        createCryptoGamer("Arwynian", 131000000000000000); 
        createCryptoGamer("Bohl", 106000000000000000);
        createCryptoGamer("Corgi", 91500000000000000);
        createCryptoGamer("Enderhero", 104000000000000000);
        createCryptoGamer("Hecatonquiro", 105000000000000000);
        createCryptoGamer("herb", 101500000000000000);
        createCryptoGamer("Kail", 103000000000000000);
        createCryptoGamer("karupin the cat", 108100000000000000);
        createCryptoGamer("LiveFree", 90100000000000000);
        createCryptoGamer("Prokiller", 100200000000000000);
        createCryptoGamer("Sanko", 101000000000000000);
        createCryptoGamer("TheHermitMonk", 100000000000000000);
        createCryptoGamer("TomiSharked", 89000000000000000);
        createCryptoGamer("Zalman", 92000000000000000);
        createCryptoGamer("xxFyMxx", 110000000000000000);
        createCryptoGamer("UncleTom", 90000000000000000);
        createCryptoGamer("legal", 115000000000000000);
        createCryptoGamer("Terpsicores", 102000000000000000);
        createCryptoGamer("triceratops", 109000000000000000);
        createCryptoGamer("souto", 85000000000000000);
    }
}