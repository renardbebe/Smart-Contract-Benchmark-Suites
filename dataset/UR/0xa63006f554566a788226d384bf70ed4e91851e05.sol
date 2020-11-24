 

pragma solidity >=0.4.0 <0.7.0;
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
}
}


 
 
 
 
contract ERC20Interface {
function totalSupply() public view returns (uint);
function balanceOf(address tokenOwner) public view returns (uint balance);
function allowance(address tokenOwner, address spender) public view returns (uint remaining);
function transfer(address to, uint tokens) public returns (bool success);
function approve(address spender, uint tokens) public returns (bool success);
function transferFrom(address from, address to, uint tokens) public returns (bool success);

event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
    _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 

contract InGRedientToken  is ERC20Interface, Owned {
    using SafeMath for uint;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    
     
     
     
    constructor() public {
        symbol = "IGR";
        name = "InGRedientToken Certification of Value Ingredients for Recipe Based Foods";
        decimals = 3; 
        _totalSupply = 1000000000000000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    
     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    
    
     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    
     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    
     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    
     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    
     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    
     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    
     
     
     
    function () external payable {
        revert();
    }
    
    
     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    
    
     
     
     
    mapping(address => mapping(address=>uint)) public balancesNFT;
    mapping(address => mapping(address=>string)) urlNFT;
    
    
    
    event  FarmerRequestedCertificate(address owner, address certAuth, uint tokens);
     
     
     
    function farmerRequestCertificate(address _certAuth, uint _tokens, string memory  _product, string memory _IngValueProperty, string memory _localGPSProduction, string memory  _dateProduction ) public returns (bool success) {
         
        allowed[owner][_certAuth] = _tokens;
        emit Approval(owner, _certAuth, _tokens);
        emit FarmerRequestedCertificate(owner, _certAuth, _tokens);
        
        
    
        return true;
    }
    
    function urlToKeccak (string memory _url) public pure returns (address b){
        bytes32 a = keccak256(abi.encodePacked(_url));
        
        assembly{
        mstore(0,a)
        b:= mload(0)
        }
        
        return b;
    }
    
    
     
     
     
     
    function certAuthIssuesCerticate(address owner, address _farmer, uint _tokens, string memory _url,string memory product,string memory IngValueProperty, string memory localGPSProduction, string memory  _dateProduction) public returns (bool success) {
        balances[owner] = balances[owner].sub(_tokens);
         
        allowed[owner][msg.sender] = 0;
        balances[_farmer] = balances[_farmer].add(_tokens);
        emit Transfer(owner, _farmer, _tokens);
    
        address a = urlToKeccak(_url);
        balancesNFT[_farmer][a]=_tokens;
        urlNFT[_farmer][a]=_url;
    
        return true;
    }
    
    
    
    
     
     
     
    function sellsIngrWithoutDepletion(address _to, uint _tokens,string memory _url) public returns (bool success) {
        string memory url=_url;  
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(msg.sender, _to, _tokens);
        
        address a = urlToKeccak(_url);
        require(balancesNFT[msg.sender][a]>_tokens);
        balancesNFT[msg.sender][a]=balancesNFT[msg.sender][a].sub(_tokens);
        balancesNFT[_to][a]=balancesNFT[_to][a].add(_tokens);
        urlNFT[_to][a]=_url;
        
        
        return true;
    }
    
     
     
     
     
     
    function sellsIntermediateGoodWithDepletion(address _to, uint _tokens,string memory _url,uint _out2inIngredientPercentage ) public returns (bool success) {
        string memory url=_url;  
        require (_out2inIngredientPercentage <= 100);  
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        
        transfer(_to, _tokens*_out2inIngredientPercentage/100);
        
        address a = urlToKeccak(_url);
        uint c =  _tokens*_out2inIngredientPercentage/100;
        require(balancesNFT[msg.sender][a]>_tokens);
        balancesNFT[msg.sender][a]=balancesNFT[msg.sender][a].sub(_tokens);
        balancesNFT[_to][a]=balancesNFT[_to][a].add(c);
        urlNFT[_to][a]=_url;
       
        return true;
    }
    
     
     
     
     
     
     
    function genAddressFromGTIN13date(string memory _GTIN13,string memory _YYMMDD) public pure returns(address b){
     
     
        
        bytes32 a = keccak256(abi.encodePacked(_GTIN13,_YYMMDD));
        
        assembly{
        mstore(0,a)
        b:= mload(0)
        }
        
        return b;
    }
    
     
     
     
     
     
     
    function transferAndWriteUrl(address _to, uint _tokens, string memory _url) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(msg.sender, _to, _tokens);
        
        address a = urlToKeccak(_url);
        require(balancesNFT[msg.sender][a]>_tokens);
        balancesNFT[msg.sender][a]=balancesNFT[msg.sender][a].sub(_tokens);
        balancesNFT[_to][a]=balancesNFT[_to][a].add(_tokens);
        urlNFT[_to][a]=_url;
        
        
        return true;
    }
    
     
     
     
     
     
    function comminglerSellsProductSKUWithProRataIngred(address _to, uint _numSKUsSold,string memory _url,uint _qttyIGRinLLSKU, string memory _GTIN13, string memory _YYMMDD ) public returns (bool success) {
        string memory url=_url;  
        address c= genAddressFromGTIN13date( _GTIN13, _YYMMDD);
        require (_qttyIGRinLLSKU >0);  
         
        transferAndWriteUrl(c, _qttyIGRinLLSKU, _url);
         
        transferAndWriteUrl(_to, (_numSKUsSold-1)*_qttyIGRinLLSKU,_url); 
        
        
        return true;
    }


}