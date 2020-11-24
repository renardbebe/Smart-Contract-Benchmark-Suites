 

pragma solidity ^0.4.23;

contract T1WinTokenConfig {
     
    event addConfigUser(
    address indexed userAddress,
    uint ethereumReinvested
    );
     event addToken(
    address indexed tokenAddress,
    string tokenName
    );
     event removeToken(
    address indexed tokenAddress,
    string tokenName
    );
     
    T1WinAdmin constant private t1WinAdmin = T1WinAdmin(0xcc258f29443d849efd5dccf233bfe29533b042bc);

    uint constant internal  configEthSpent       = 1   ether;

    
    address[] configUserList; 

    T1Wdatasets.TokenConfiguration[] public tokenListArray;
     
    mapping (address => T1Wdatasets.TokenConfiguration) public tokenListMap;
     
    mapping (address => T1Wdatasets.AddConfigurationUser) public configurationUserMap;
    mapping (address => uint256) public configurationUserCheck;
   address private adminAddress;
    modifier onlyAuthorizedAdmin {
        adminAddress=t1WinAdmin.getAdmin();
        require(adminAddress == msg.sender);
        _;
    }
    modifier isWithinETHLimits(uint256 _eth) {
         
        require(_eth == 1000000000000000000);
        _;    
    }
     
    function getTokenArrayLength() 
        public
        view
        returns(uint) 
    {
        return tokenListArray.length;
    }    
     
    function getToken(uint n)
        public 
        view
        returns (address, string,uint8,bool ) {
        return (tokenListArray[n].tokenAddress, tokenListArray[n].tokenName,tokenListArray[n].tokenDecimals,tokenListArray[n].used);
    }  
    function getTokenByAddress(address a)
        public 
        view
        returns (address, string,uint8,bool ) {
        T1Wdatasets.TokenConfiguration token = tokenListMap[a];
        return (token.tokenAddress, token.tokenName,token.tokenDecimals,token.used);
    } 
    function getTokenNameByAddress(address a)
        public 
        view
        returns (string ) {
             T1Wdatasets.TokenConfiguration token = tokenListMap[a];
             return(token.tokenName);
        }
      function getTokenDecimalsByAddress(address a)
        public 
        view
        returns (uint8 ) {
             T1Wdatasets.TokenConfiguration token = tokenListMap[a];
             return(token.tokenDecimals);
        }   
      
    function addNewTokenByAdmin(address _tokenAddress, string _tokenName,uint8 decimal)
            onlyAuthorizedAdmin()
            public
        {
             
             require(!tokenListMap[_tokenAddress].used);
             tokenListMap[_tokenAddress]= T1Wdatasets.TokenConfiguration(_tokenAddress, _tokenName,decimal,true);
             tokenListArray.push(tokenListMap[_tokenAddress]);
             emit addToken(_tokenAddress, _tokenName);
        }
      
    function removeNewTokenByAdmin(address _tokenAddress)
            onlyAuthorizedAdmin()
            public
        {
             
            delete tokenListMap[_tokenAddress];
             
            for (uint i = 0; i < tokenListArray.length; i++) {
                if (tokenListArray[i].tokenAddress == _tokenAddress) {
                    tokenListArray[i] = tokenListArray[tokenListArray.length - 1];
                    tokenListArray.length -= 1;
                    break;
                }
            }
          
        }
    function addNewToken(address _tokenAddress, bytes32 _tokenName)
            isWithinETHLimits(msg.value)
            public
            payable
        {
          uint256 checkUserStatu = configurationUserCheck[msg.sender];
             
            
            if(checkUserStatu == 0){
                 
                configurationUserCheck[msg.sender]=1;
                 
                T1Wdatasets.AddConfigurationUser memory configurationUser ; 
                configurationUser.addr = msg.sender;
                configurationUser.ethTotalAmount += msg.value;
                configurationUserMap[msg.sender] = configurationUser;
                emit addConfigUser(msg.sender , msg.value);
               
            }
    
             
            
              
        }

}

 

interface T1WinAdmin {
    function getAdmin() external view returns(address);
}
 
library T1Wdatasets {

    struct TokenConfiguration{
        address tokenAddress;  
        string tokenName;   
        uint8 tokenDecimals;  
        bool used;
      
    }
    
    
    
     
    struct AddConfigurationUser {
        address addr;    
        uint256 ethTotalAmount;  
        bool used;
    }
  
    
}