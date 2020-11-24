 

 
pragma solidity ^0.4.24;

 
contract Owned {

    address public owner;
    address public proposedOwner;

    constructor() public
    {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender) == true, 'Require owner to execute transaction');
        _;
    }


    function isOwner(address _address) public view returns (bool) {
        return (_address == owner);
    }


    function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool success) {
        require(_proposedOwner != address(0), 'Require proposedOwner != address(0)');
        require(_proposedOwner != address(this), 'Require proposedOwner != address(this)');
        require(_proposedOwner != owner, 'Require proposedOwner != owner');

        proposedOwner = _proposedOwner;
        return true;
    }


    function completeOwnershipTransfer() public returns (bool success) {
        require(msg.sender == proposedOwner, 'Require msg.sender == proposedOwner');

        owner = msg.sender;
        proposedOwner = address(0);

        return true;
    }
}

 
 
 
contract OpsManaged is Owned {

    address public opsAddress;


    constructor() public
        Owned()
    {
    }


    modifier onlyOwnerOrOps() {
        require(isOwnerOrOps(msg.sender), 'Require only owner or ops');
        _;
    }


    function isOps(address _address) public view returns (bool) {
        return (opsAddress != address(0) && _address == opsAddress);
    }


    function isOwnerOrOps(address _address) public view returns (bool) {
        return (isOwner(_address) || isOps(_address));
    }


    function setOpsAddress(address _newOpsAddress) public onlyOwner returns (bool success) {
        require(_newOpsAddress != owner, 'Require newOpsAddress != owner');
        require(_newOpsAddress != address(this), 'Require newOpsAddress != address(this)');

        opsAddress = _newOpsAddress;

        return true;
    }
}

 
 
 
contract Finalizable is OpsManaged {

    FinalizableState public finalized;
    
    enum FinalizableState { 
        None,
        Finalized
    }

    event Finalized();


    constructor() public OpsManaged()
    {
        finalized = FinalizableState.None;
    }


    function finalize() public onlyOwner returns (bool success) {
        require(finalized == FinalizableState.None, 'Require !finalized');

        finalized = FinalizableState.Finalized;

        emit Finalized();

        return true;
    }
}

 
 
 
library Math {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 r = a + b;

        require(r >= a, 'Require r >= a');

        return r;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, 'Require a >= b');

        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 r = a * b;

        require(r / a == b, 'Require r / a == b');

        return r;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

 
 
 
 
 
contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 
 
 
contract ERC20Token is ERC20Interface {

    using Math for uint256;

    string public  name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) allowed;


    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply, address _initialTokenHolder) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

         
        balances[_initialTokenHolder] = _totalSupply;
        allowed[_initialTokenHolder][_initialTokenHolder] = balances[_initialTokenHolder];

         
        emit Transfer(0x0, _initialTokenHolder, _totalSupply);
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) { 
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);

            emit Transfer(msg.sender, _to, _value);

            return true;
        } else { 
            return false;
        }
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);

            emit Transfer(_from, _to, _value);

            return true;
        } else { 
            return false;
        }
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }
}

 
 
 

 
 
 
 
 
contract FinalizableToken is ERC20Token, OpsManaged, Finalizable {

    using Math for uint256;


     
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public
        ERC20Token(_name, _symbol, _decimals, _totalSupply, msg.sender)
        Finalizable()
    {
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        validateTransfer(msg.sender, _to);

        return super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        validateTransfer(msg.sender, _to);

        return super.transferFrom(_from, _to, _value);
    }


    function validateTransfer(address _sender, address _to) internal view {
         
        if (finalized == FinalizableState.Finalized) {
            return;
        }
        

        if (isOwner(_to)) {
            return;
        }

         
         
        require(isOwnerOrOps(_sender), 'Require is owner or ops allowed to initiate transfer');
    }
}



 
 
 
contract PBTTTokenConfig {

    string  internal constant TOKEN_SYMBOL      = 'PBTT';
    string  internal constant TOKEN_NAME        = 'Purple Butterfly Token (PBTT)';
    uint8   internal constant TOKEN_DECIMALS    = 3;

    uint256 internal constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 internal constant TOKEN_TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}


 
 
 
contract PBTTToken is FinalizableToken, PBTTTokenConfig {
      
    uint256 public buyPriceEth = 0.0002 ether;                               
    uint256 public sellPriceEth = 0.0001 ether;                              
    uint256 public gasForPBTT = 0.005 ether;                                 
    uint256 public PBTTForGas = 1;                                           
    uint256 public gasReserve = 1 ether;                                     

     
     
    uint256 public minBalanceForAccounts = 0.005 ether;                     
    uint256 public totalTokenSold = 0;
    
    enum HaltState { 
        Unhalted,
        Halted        
    }

    HaltState public halts;

    constructor() public
        FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY)
    {
        halts = HaltState.Unhalted;
        finalized = FinalizableState.None;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(halts == HaltState.Unhalted, 'Require smart contract is not in halted state');

         
        require(_value >= PBTTForGas, 'Token amount is not enough to transfer'); 
         
        if (!isOwnerOrOps(msg.sender) && _to == address(this)) {
             
            sellPBTTAgainstEther(_value);                             
            return true;
        } else {
            if(isOwnerOrOps(msg.sender)) {
                return super.transferFrom(owner, _to, _value);
            }
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(halts == HaltState.Unhalted, 'Require smart contract is not in halted state');
        return super.transferFrom(_from, _to, _value);
    }
    
     
    function setEtherPrices(uint256 newBuyPriceEth, uint256 newSellPriceEth) public onlyOwnerOrOps {
         
        buyPriceEth = newBuyPriceEth;                                       
        sellPriceEth = newSellPriceEth;
    }

    function setGasForPBTT(uint256 newGasAmountInWei) public onlyOwnerOrOps {
        gasForPBTT = newGasAmountInWei;
    }

     
    function setPBTTForGas(uint256 newPBTTAmount) public onlyOwnerOrOps {
        PBTTForGas = newPBTTAmount;
    }

    function setGasReserve(uint256 newGasReserveInWei) public onlyOwnerOrOps {
        gasReserve = newGasReserveInWei;
    }

    function setMinBalance(uint256 minimumBalanceInWei) public onlyOwnerOrOps {
        minBalanceForAccounts = minimumBalanceInWei;
    }

    function getTokenRemaining() public view returns (uint256 total){
        return (TOKEN_TOTALSUPPLY.div(DECIMALSFACTOR)).sub(totalTokenSold);
    }

     
    function buyPBTTAgainstEther() private returns (uint256 tokenAmount) {
         
        require(buyPriceEth > 0, 'buyPriceEth must be > 0');
        require(msg.value >= buyPriceEth, 'Transfer money must be enough for 1 token');
        
         
        tokenAmount = (msg.value.mul(DECIMALSFACTOR)).div(buyPriceEth);                
        
         
        require(balances[owner] >= tokenAmount, 'Not enough token balance');
        
         
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);            

         
        balances[owner] = balances[owner].sub(tokenAmount);

         
        emit Transfer(owner, msg.sender, tokenAmount);                           
        
        totalTokenSold = totalTokenSold + tokenAmount;
		
        return tokenAmount;
    }

    function sellPBTTAgainstEther(uint256 amount) private returns (uint256 revenue) {
         
        require(sellPriceEth > 0, 'sellPriceEth must be > 0');
        
        require(amount >= PBTTForGas, 'Sell token amount must be larger than PBTTForGas value');

         
        require(balances[msg.sender] >= amount, 'Token balance is not enough to sold');
        
        require(msg.sender.balance >= minBalanceForAccounts, 'Seller balance must be enough to pay the transaction fee');
        
         
        revenue = (amount.div(DECIMALSFACTOR)).mul(sellPriceEth);                                 

         
        uint256 remaining = address(this).balance.sub(revenue);
        require(remaining >= gasReserve, 'Remaining contract balance is not enough for reserved');

         
        balances[owner] = balances[owner].add(amount);         
         
        balances[msg.sender] = balances[msg.sender].sub(amount);            

         
         
         
        msg.sender.transfer(revenue);
 
         
        emit Transfer(msg.sender, owner, amount);                            
        return revenue;   
    }

     
     
    function burn(uint256 _amount) public returns (bool success) {
        require(_amount > 0, 'Token amount to burn must be larger than 0');

        address account = msg.sender;
        require(_amount <= balanceOf(account), 'You cannot burn token you dont have');

        balances[account] = balances[account].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        return true;
    }

     
    function reclaimTokens() public onlyOwner returns (bool success) {

        address account = address(this);
        uint256 amount = balanceOf(account);

        if (amount == 0) {
            return false;
        }

        balances[account] = balances[account].sub(amount);
        balances[owner] = balances[owner].add(amount);

        return true;
    }

     
    function withdrawFundToOwner() public onlyOwner {
         
        uint256 eth = address(this).balance; 
        owner.transfer(eth);
    }

     
    function withdrawFundToAddress(address _ownerOtherAdress) public onlyOwner {
         
        uint256 eth = address(this).balance; 
        _ownerOtherAdress.transfer(eth);
    }

     
    function haltsTrades() public onlyOwnerOrOps returns (bool success) {
        halts = HaltState.Halted;
        return true;
    }

    function unhaltsTrades() public onlyOwnerOrOps returns (bool success) {
        halts = HaltState.Unhalted;
        return true;
    }

    function() public payable { 
        if(msg.sender != owner) {
            require(finalized == FinalizableState.Finalized, 'Require smart contract is finalized');
            require(halts == HaltState.Unhalted, 'Require smart contract is not halted');
            
            buyPBTTAgainstEther(); 
        }
    } 

}