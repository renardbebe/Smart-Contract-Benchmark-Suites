 

pragma solidity ^0.4.18;

 

contract WallCryptoStreet {

    address ceoAddress = 0x9aFbaA3003D9e75C35FdE2D1fd283b13d3335f00;
    address cfoAddress = 0x23a49A9930f5b562c6B1096C3e6b5BEc133E8B2E;
    
    modifier onlyCeo() {
        require (msg.sender == ceoAddress);
        _;
    }
    
    struct Company {
        string name;
        address ownerAddress;
        uint256 curPrice;
        uint256 curAdPrice;
        string curAdText;
        string curAdLink;
        uint256 volume;
    }
    Company[] companies;

    struct Share {
        uint companyId;
        address ownerAddress;
        uint256 curPrice;
    }
    Share[] shares;

     
    mapping (address => uint) public addressSharesCount;
    bool companiesAreInitiated;
    bool isPaused;
    
     
    function pauseGame() public onlyCeo {
        isPaused = true;
    }
    function unPauseGame() public onlyCeo {
        isPaused = false;
    }
    function GetIsPauded() public view returns(bool) {
       return(isPaused);
    }

     
    function purchaseCompany(uint _companyId) public payable {
        require(msg.value == companies[_companyId].curPrice);
        require(isPaused == false);

         
        uint256 commission5percent = ((msg.value / 10)/2);

         
        uint256 commissionOwner = msg.value - commission5percent;  
        companies[_companyId].ownerAddress.transfer(commissionOwner);

         
        cfoAddress.transfer(commission5percent);  

         
        companies[_companyId].ownerAddress = msg.sender;
        companies[_companyId].curPrice = companies[_companyId].curPrice + (companies[_companyId].curPrice / 2);
        
         
        companies[_companyId].volume = companies[_companyId].volume + msg.value;
    }
    
     
    function purchaseAd(uint _companyId, string adText, string adLink) public payable {
        require(msg.value == companies[_companyId].curAdPrice);

         
        companies[_companyId].curAdText = adText;
        companies[_companyId].curAdLink = adLink;

         
        uint256 commission1percent = (msg.value / 100);
        companies[_companyId].ownerAddress.transfer(commission1percent * 40);    
        cfoAddress.transfer(commission1percent * 10);    

        uint256 commissionShareholders = commission1percent * 50;    
        uint256 commissionOneShareholder = commissionShareholders / 5;

         
        address[] memory shareholdersAddresses = getCompanyShareholders(_companyId);
         
        for (uint8 i = 0; i < 5; i++) {
            shareholdersAddresses[i].transfer(commissionOneShareholder);
        }

         
        companies[_companyId].curAdPrice = companies[_companyId].curAdPrice + (companies[_companyId].curAdPrice / 2);

         
        companies[_companyId].volume = companies[_companyId].volume + msg.value;
    }

     
    function purchaseShare(uint _shareId) public payable {
        require(msg.value == shares[_shareId].curPrice);
    
        uint256 commission1percent = (msg.value / 100);
         
        if(shares[_shareId].ownerAddress == cfoAddress) {
             
            companies[shares[_shareId].companyId].ownerAddress.transfer(commission1percent * 80);  
            cfoAddress.transfer(commission1percent * 20);     
        } else {
             
            shares[_shareId].ownerAddress.transfer(commission1percent * 85);     
            companies[shares[_shareId].companyId].ownerAddress.transfer(commission1percent * 10);  
            cfoAddress.transfer(commission1percent * 5);     
        }
         
        addressSharesCount[shares[_shareId].ownerAddress]--;
        
         
        shares[_shareId].ownerAddress = msg.sender;
        addressSharesCount[msg.sender]++;
        
         
        shares[_shareId].curPrice = shares[_shareId].curPrice + (shares[_shareId].curPrice / 2);
        
         
        companies[shares[_shareId].companyId].volume = companies[shares[_shareId].companyId].volume + msg.value;
    }

     
    function getCompanyShareholders(uint _companyId) public view returns(address[]) {
        address[] memory result = new address[](5);
        uint counter = 0;
        for (uint i = 0; i < shares.length; i++) {
          if (shares[i].companyId == _companyId) {
            result[counter] = shares[i].ownerAddress;
            counter++;
          }
        }
        return result;
    }

     
    function updateCompanyPrice(uint _companyId, uint256 _newPrice) public {
        require(_newPrice > 0);
        require(companies[_companyId].ownerAddress == msg.sender);
        require(_newPrice < companies[_companyId].curPrice);
        companies[_companyId].curPrice = _newPrice;
    }
    
     
    function updateSharePrice(uint _shareId, uint256 _newPrice) public {
        require(_newPrice > 0);
        require(shares[_shareId].ownerAddress == msg.sender);
        require(_newPrice < shares[_shareId].curPrice);
        shares[_shareId].curPrice = _newPrice;
    }
    
     
    function getCompany(uint _companyId) public view returns (
        string name,
        address ownerAddress,
        uint256 curPrice,
        uint256 curAdPrice,
        string curAdText,
        string curAdLink,
        uint shareId,    
        uint256 sharePrice,   
        uint256 volume
    ) {
        Company storage _company = companies[_companyId];

        name = _company.name;
        ownerAddress = _company.ownerAddress;
        curPrice = _company.curPrice;
        curAdPrice = _company.curAdPrice;
        curAdText = _company.curAdText;
        curAdLink = _company.curAdLink;
        shareId = getLeastExpensiveShare(_companyId,0);
        sharePrice = getLeastExpensiveShare(_companyId,1);
        volume = _company.volume;
    }

     
    function getShare(uint _shareId) public view returns (
        uint companyId,
        address ownerAddress,
        uint256 curPrice
    ) {
        Share storage _share = shares[_shareId];

        companyId = _share.companyId;
        ownerAddress = _share.ownerAddress;
        curPrice = _share.curPrice;
    }
    
     
    function getMyShares() public view returns(uint[]) {
        uint[] memory result = new uint[](addressSharesCount[msg.sender]);
        uint counter = 0;
        for (uint i = 0; i < shares.length; i++) {
          if (shares[i].ownerAddress == msg.sender) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    }
    
     
    function getLeastExpensiveShare(uint _companyId, uint _type) public view returns(uint) {
        uint _shareId = 0;
        uint256 _sharePrice = 999000000000000000000;

         
        for (uint8 i = 0; i < shares.length; i++) {
             
            if(shares[i].companyId == _companyId) {
                 
                if(shares[i].curPrice < _sharePrice && shares[i].ownerAddress != msg.sender) {
                    _sharePrice = shares[i].curPrice;
                    _shareId = i;
                }
            }
        }

         
        if(_type == 0) {
            return(_shareId);
        } else {
            return(_sharePrice);
        }
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
    
     
    function createCompany(string _companyName, uint256 _companyPrice) public onlyCeo {
        uint companyId = companies.push(Company(_companyName, cfoAddress, _companyPrice, 10000000000000000, "0", "#",0)) - 1;
         
        uint256 sharePrice = _companyPrice / 10;
        
         
        shares.push(Share(companyId, cfoAddress, sharePrice));
        shares.push(Share(companyId, cfoAddress, sharePrice));
        shares.push(Share(companyId, cfoAddress, sharePrice));
        shares.push(Share(companyId, cfoAddress, sharePrice));
        shares.push(Share(companyId, cfoAddress, sharePrice));
    }
    
     
    function InitiateCompanies() public onlyCeo {
        require(companiesAreInitiated == false);
        createCompany("Apple", 350000000000000000); 
        createCompany("Snapchat", 200000000000000000); 
        createCompany("Facebook", 250000000000000000); 
        createCompany("Google", 250000000000000000); 
        createCompany("Microsoft", 350000000000000000); 
        createCompany("Nintendo", 150000000000000000); 
        createCompany("Mc Donald", 250000000000000000); 
        createCompany("Kodak", 100000000000000000);
        createCompany("Twitter", 100000000000000000);

    }
}