 

pragma solidity ^0.4.20;

contract owned {
    address public owner;

    function owned () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

}

contract token {
    string public standard = '';
    string public name; 
    string public symbol; 
    uint8 public decimals = 18;  
    uint256 public totalSupply; 

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);   
    event Burn(address indexed from, uint256 value);   

    function token(uint256 initialSupply, string tokenName, string tokenSymbol) public {

        totalSupply = initialSupply * 10 ** uint256(decimals);     

        balanceOf[this] = totalSupply;

        name = tokenName;
        symbol = tokenSymbol;

    }

    function _transfer(address _from, address _to, uint256 _value) internal {

      require(_to != 0x0);

      require(balanceOf[_from] >= _value);

      require(balanceOf[_to] + _value > balanceOf[_to]);

      uint previousBalances = balanceOf[_from] + balanceOf[_to];

      balanceOf[_from] -= _value;

      balanceOf[_to] += _value;

      Transfer(_from, _to, _value);

      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }
    
    function transfer(address _to, uint256 _value)  public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);    
        
        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    

        balanceOf[msg.sender] -= _value;

        totalSupply -= _value;

        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {

        require(balanceOf[_from] >= _value);

        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;

        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}


contract MLTKTOKEN is owned, token {

    uint256 public sellPrice;

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function MLTKTOKEN (
      uint256 initialSupply,
      string tokenName,
      string tokenSymbol,
      address centralMinter
    ) payable token (initialSupply, tokenName, tokenSymbol) public {

        if(centralMinter != 0 ) owner = centralMinter;

        sellPrice = 2;     
   
    }

    address fromAddress;
    uint256 value;
    uint256 code;
    uint256 team;

    function buyeths(uint256 _code, uint256 _team)public payable {
        fromAddress = msg.sender;
        value = msg.value;
        code = _code;
        team = _team;
    }

    function getInfo()public constant returns (address, uint256, uint256, uint256)
    {
        return (fromAddress, value, code, team);
    }


    function withdraw(address _to,uint256 _eth) onlyOwner public
    {
        address send_to_address = _to;
        send_to_address.transfer(_eth);
    }


    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice) onlyOwner public {
        sellPrice = newSellPrice;
    }


    function sell(uint amount)public returns (uint256 revenue){
    if(frozenAccount[msg.sender]){
        revert();
    }
    require(balanceOf[msg.sender] >= amount);          
    balanceOf[this] += amount;                         
    balanceOf[msg.sender] -= amount;                   
    revenue = amount * (sellPrice/10000);
    msg.sender.transfer(revenue);                      
    Transfer(msg.sender, this, amount);                
    return revenue;                                    
    }

    function transferTo(address _to,uint amount) onlyOwner public returns(uint256 revenue) {
        require(balanceOf[this] >= amount);
        balanceOf[this] -= amount;
        balanceOf[_to] += amount;
        Transfer(this, msg.sender, amount);
        revenue = balanceOf[this];
        return revenue;
    }
    
    
    function ()public payable{

    }
}