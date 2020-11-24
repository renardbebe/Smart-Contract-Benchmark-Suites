 

interface IYeekFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) external view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) external view returns (uint256);
}

interface ITradeableAsset {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function decimals() external view returns (uint256);
    function transfer(address _to, uint256 _value) external;
    function balanceOf(address _address) external view returns (uint256);
}

 
contract Administered {
    address public creator;
    uint public commission = 1;
    mapping (address => bool) public admins;
    
    constructor()  public {
        creator = msg.sender;
        admins[creator] = true;
    }

     
     
    modifier onlyOwner {
        require(creator == msg.sender);
        _;
    }
    
     
     
    modifier onlyAdmin {
        require(admins[msg.sender] || creator == msg.sender);
        _;
    }

     
    function grantAdmin(address newAdmin) onlyOwner  public {
        _grantAdmin(newAdmin);
    }

    function _grantAdmin(address newAdmin) internal
    {
        admins[newAdmin] = true;
    }

     
    function changeOwner(address newOwner) onlyOwner public {
        creator = newOwner;
    }

     
    function revokeAdminStatus(address user) onlyOwner public {
        admins[user] = false;
    }
}

 
 

contract Exchanger is Administered {
    bool public enabled = false;     

     
    ITradeableAsset public tokenContract;
     
    IYeekFormula public formulaContract;
     
    uint32 public weight;

     

    constructor(address _token, 
                uint32 _weight,
                address _formulaContract) {
        require (_weight > 0 && weight <= 1000000);
        
        weight = _weight;
        tokenContract = ITradeableAsset(_token);
        formulaContract = IYeekFormula(_formulaContract);
    }

     
     
     

    event Buy(address indexed purchaser, uint256 amountInWei, uint256 amountInToken);
    event Sell(address indexed seller, uint256 amountInToken, uint256 amountInWei);


     
    
     
    function depositTokens(uint amount) onlyOwner public {
        tokenContract.transferFrom(msg.sender, this, amount);
    }
        
     
     function depositEther() onlyOwner public payable {
         
     }

     
    function withdrawTokens(uint amount) onlyOwner public {
        tokenContract.transfer(msg.sender, amount);
    }

     
    function withdrawEther(uint amountInWei) onlyOwner public {
        msg.sender.transfer(amountInWei);  
    }

     
     function enable() onlyAdmin public {
         enabled = true;
     }

      
     function disable() onlyAdmin public {
         enabled = false;
     }

      
     function setReserveWeight(uint32 ppm) onlyAdmin public {
         require (ppm>0 && ppm<=1000000);
         weight = ppm;
     }

     
     

     
    function getReserveBalances() public view returns (uint256, uint256) {
        return (tokenContract.balanceOf(this), address(this).balance);
    }


     
    function getQuotePrice() public view returns(uint) {
        uint tokensPerEther = 
        formulaContract.calculatePurchaseReturn(
            tokenContract.totalSupply(),
            address(this).balance,
            weight,
            1 ether 
        ); 

        return tokensPerEther;
    }

     
    function getPurchasePrice(uint256 amountInWei) public view returns(uint) {
        uint tokensPerEther =  formulaContract.calculatePurchaseReturn(
            tokenContract.totalSupply(),
            address(this).balance,
            weight,
            amountInWei 
        ); 
        
        return tokensPerEther - (tokensPerEther * commission / 100);
    }

     
    function getSalePrice(uint256 tokensToSell) public view returns(uint) {
        uint weiRaw= formulaContract.calculateSaleReturn(
            tokenContract.totalSupply(),
            address(this).balance,
            weight,
            tokensToSell 
        ); 
        
        return weiRaw - (weiRaw * commission / 100);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    function buy(uint minPurchaseReturn) public payable {
        uint amount = formulaContract.calculatePurchaseReturn(
            tokenContract.totalSupply(),
            address(this).balance - msg.value,
            weight,
            msg.value);
        require (enabled);
        require (amount >= minPurchaseReturn);
        require (tokenContract.balanceOf(this) >= amount);
        emit Buy(msg.sender, msg.value, amount);
        tokenContract.transfer(msg.sender, amount);
    }
     
     function sell(uint quantity, uint minSaleReturn) public {
         uint amountInWei = formulaContract.calculateSaleReturn(
             tokenContract.totalSupply(),
             address(this).balance,
             weight,
             quantity
         );
         require (enabled);
         require (amountInWei >= minSaleReturn);
         require (amountInWei <= address(this).balance);
         require (tokenContract.transferFrom(msg.sender, this, quantity));
         emit Sell(msg.sender, quantity, amountInWei);
         msg.sender.transfer(amountInWei);  
     }
}