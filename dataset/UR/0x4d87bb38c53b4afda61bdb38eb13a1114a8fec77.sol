 

pragma solidity 0.4.24;
 
 
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract APIRegistry is Ownable {

    struct APIForSale {
        uint pricePerCall;
        bytes32 sellerUsername;
        bytes32 apiName;
        address sellerAddress;
        string hostname;
        string docsUrl;
    }

    mapping(string => uint) internal apiIds;
    mapping(uint => APIForSale) public apis;

    uint public numApis;
    uint public version;

     
     
     
    constructor() public {
        numApis = 0;
        version = 1;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
     
     
    function listApi(uint pricePerCall, bytes32 sellerUsername, bytes32 apiName, string hostname, string docsUrl) public {
         
        require(pricePerCall != 0 && sellerUsername != "" && apiName != "" && bytes(hostname).length != 0);
        
         
        require(apiIds[hostname] == 0);

        numApis += 1;
        apiIds[hostname] = numApis;

        APIForSale storage api = apis[numApis];

        api.pricePerCall = pricePerCall;
        api.sellerUsername = sellerUsername;
        api.apiName = apiName;
        api.sellerAddress = msg.sender;
        api.hostname = hostname;
        api.docsUrl = docsUrl;
    }

     
     
     
    function getApiId(string hostname) public view returns (uint) {
        return apiIds[hostname];
    }

     
     
     
    function getApiByIdWithoutDynamics(
        uint apiId
    ) 
        public
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername,
            bytes32 apiName, 
            address sellerAddress
        ) 
    {
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
    }

     
     
     
    function getApiById(
        uint apiId
    ) 
        public 
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername, 
            bytes32 apiName, 
            address sellerAddress, 
            string hostname, 
            string docsUrl
        ) 
    {
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
        hostname = api.hostname;
        docsUrl = api.docsUrl;
    }

     
     
     
    function getApiByName(
        string _hostname
    ) 
        public 
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername, 
            bytes32 apiName, 
            address sellerAddress, 
            string hostname, 
            string docsUrl
        ) 
    {
        uint apiId = apiIds[_hostname];
        if (apiId == 0) {
            return;
        }
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
        hostname = api.hostname;
        docsUrl = api.docsUrl;
    }

     
     
     
    function editApi(uint apiId, uint pricePerCall, address sellerAddress, string docsUrl) public {
        require(apiId != 0 && pricePerCall != 0 && sellerAddress != address(0));

        APIForSale storage api = apis[apiId];

         
        require(
            api.pricePerCall != 0 && api.sellerUsername != "" && api.apiName != "" &&  bytes(api.hostname).length != 0 && api.sellerAddress != address(0)
        );

         
         
        require(msg.sender == api.sellerAddress || msg.sender == owner);

        api.pricePerCall = pricePerCall;
        api.sellerAddress = sellerAddress;
        api.docsUrl = docsUrl;
    }
}