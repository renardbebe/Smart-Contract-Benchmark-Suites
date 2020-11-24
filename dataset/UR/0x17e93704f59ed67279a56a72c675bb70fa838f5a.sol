 

pragma solidity 0.4.25;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
   constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Buyers{
   
    struct Buyer{
        
        string   name;  
        string   country;
        string   city; 
        string   b_address;
        string   mobile;  
    }
    mapping(address=>Buyer) public registerbuyer;
    event BuyerAdded(address  from, string name,string country,string city,string b_address,string mobile);
    
    
      
    function registerBuyer(string _name,string _country,string _city,string _address,string _mobile) public returns(bool){
      
         require(bytes(_name).length!=0 &&
             bytes(_country).length!=0 &&
             bytes(_city).length!=0 &&
             bytes(_address).length!=0 &&
             bytes(_mobile).length!=0  
             
        );
        registerbuyer[msg.sender]=Buyer(_name,_country,_city,_address,_mobile);
        emit BuyerAdded(msg.sender,_name,_country,_city,_address,_mobile);
        return true;
        
    }
   
    function getBuyer() public constant returns(string name,string country, string city,string _address,string mobile ){
        return (registerbuyer[msg.sender].name,registerbuyer[msg.sender].country,registerbuyer[msg.sender].city,registerbuyer[msg.sender].b_address,registerbuyer[msg.sender].mobile);
    }
    
    function getBuyerbyaddress(address _useraddress) public constant returns(string name,string country, string city,string _address,string mobile ){
        return (registerbuyer[_useraddress].name,registerbuyer[_useraddress].country,registerbuyer[_useraddress].city,registerbuyer[_useraddress].b_address,registerbuyer[_useraddress].mobile);
    }
    
}

contract ProductsInterface {
     
    struct Product {  
        uint256  id;
        string   name;  
        string   image;
        uint256  price;
        string   detail;
        address  _seller;
         
    }
    event ProductAdded(uint256 indexed id,address seller, string  name,string  image, uint256  price,string  detail );
   
   
    function addproduct(string _name,string _image,uint256 _price,string _detail)   public   returns (bool success);
    function updateprice(uint _index, uint _price) public returns (bool success);
  
   function getproduuct(uint _index) public constant returns(uint256 id,string name,string image,uint256  price,string detail, address _seller);
   function getproductprices() public constant returns(uint256[]);
   
}

contract OrderInterface{
    struct Order {  
        uint256  id;
        uint256   quantity;  
        uint256   product_index;  
        uint256  price;
       
        address  buyer;
        address  seller;
        uint256 status;
         
    }
    uint256 public order_counter;
    mapping (uint => Order) public orders;
     
    function placeorder(  uint256   quantity,uint256   product_index)  public returns(uint256);
    event OrderPlace(uint256 indexed id, uint256   quantity,uint256   product_index,string   name,address  buyer, address  seller );
   
}

contract FeedToken is  ProductsInterface,OrderInterface, ERC20Interface,Ownable,Buyers {

   using SafeMath for uint256;
    
    uint256 public counter=0;
    mapping (uint => Product) public seller_products;
    mapping (uint => uint) public products_price;
    mapping (address=> uint) public seller_total_products;
    
   string public name;
   string public symbol;
   uint256 public decimals;

   uint256 public _totalSupply;
   uint256 order_counter=0;
   mapping(address => uint256) tokenBalances;
   address ownerWallet;
    
   mapping (address => mapping (address => uint256)) allowed;
   
    
    constructor(address wallet) public {
        owner = wallet;
        name  = "Feed";
        symbol = "FEED";
        decimals = 18;
        _totalSupply = 1000000000 * 10 ** uint(decimals);
        tokenBalances[ msg.sender] = _totalSupply;    
    }
    
      
     function balanceOf(address tokenOwner) public constant returns (uint balance) {
         return tokenBalances[tokenOwner];
     }
  
      
     function transfer(address to, uint tokens) public returns (bool success) {
         require(to != address(0));
         require(tokens <= tokenBalances[msg.sender]);
          
         tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(tokens);
         tokenBalances[to] = tokenBalances[to].add(tokens);
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
     function checkUser() public constant returns(string ){
         require(bytes(registerbuyer[msg.sender].name).length!=0);
          
             return "Register User";
     }
     
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= tokenBalances[_from]);
    require(_value <= allowed[_from][msg.sender]);
     
    tokenBalances[_from] = tokenBalances[_from].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  
   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

      
      
      
     function totalSupply() public constant returns (uint) {
         return _totalSupply  - tokenBalances[address(0)];
     }
     
    
     
      
      
      
      
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }
     
      
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

     
      
      
      
     function () public payable {
         revert();
     }
 
 
      
      
      
     function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
         return ERC20Interface(tokenAddress).transfer(owner, tokens);
     }
     
    
     function placeorder( uint256   quantity,uint256   product_index)  public  returns(uint256) {
         
        require(counter>=product_index && product_index>0);
        require(bytes(registerbuyer[msg.sender].name).length!=0); 
         
        transfer(seller_products[product_index]._seller,seller_products[product_index].price*quantity);
        orders[order_counter] = Order(order_counter,quantity,product_index,seller_products[product_index].price, msg.sender,seller_products[product_index]._seller,0);
        
        emit OrderPlace(order_counter,quantity, product_index,  seller_products[product_index].name, msg.sender, seller_products[product_index]._seller );
        order_counter++;
        return counter;
    }
    
     
     
     
   
   
    function addproduct(string _name,string _image,uint256 _price,string _detail)   public   returns (bool success){
          require(bytes(_name).length!=0 &&
             bytes(_image).length!=0 &&
             bytes(_detail).length!=0 
            
             
        );
        counter++;
        seller_products[counter] = Product(counter,_name,_image, _price,_detail,msg.sender);
        products_price[counter]=_price;
        emit ProductAdded(counter,msg.sender,_name,_image,_price,_detail);
        return true;
   }
  
   function updateprice(uint _index, uint _price) public returns (bool success){
      require(seller_products[_index]._seller==msg.sender);
       
     
      seller_products[_index].price=_price;
      products_price[_index]=_price;
      return true;
  }
  
   function getproduuct(uint _index) public constant returns(uint256 ,string ,string ,uint256  ,string , address )
   {
       return(seller_products[_index].id,seller_products[_index].name,seller_products[_index].image,products_price[_index],seller_products[_index].detail,seller_products[_index]._seller);
   }
   
   function getproductprices() public constant returns(uint256[])
   {
       uint256[] memory price = new uint256[](counter);
        
        for (uint i = 0; i <counter; i++) {
           
            price[i]=products_price[i+1];
             
        }
      return price;
   }
}