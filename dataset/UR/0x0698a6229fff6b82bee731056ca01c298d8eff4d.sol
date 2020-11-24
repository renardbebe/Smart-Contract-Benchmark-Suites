 

 

 
contract TokenInterface {

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount);

    mapping (address =>  
        uint256) balances;

    mapping (address =>  
    mapping (address =>  
        uint256)) allowed;

    uint256 public totalSupply;

    function balanceOf(address _owner)
    constant
    returns (uint256 balance);

    function transfer(address _to, uint256 _amount)
    returns (bool success);

    function transferFrom(address _from, address _to, uint256 _amount)
    returns (bool success);

    function approve(address _spender, uint256 _amount)
    returns (bool success);

    function allowance(address _owner, address _spender)
    constant
    returns (uint256 remaining);

}

 
contract Spork is TokenInterface {

     
    address constant TheDAO = 0xbb9bc244d798123fde783fcc1c72d3bb8c189413;

    event Mint(
        address indexed _sender,
        uint256 indexed _amount,
        string _lulz);

     
    string public name = "Spork";
    string public symbol = "SPRK";
    string public version = "Spork:0.1";
    uint8 public decimals = 0;

     
    function () {
        throw;  
    }

     
    function mint(uint256 _amount, string _lulz)
    returns (bool success) {
        if (totalSupply + _amount <= totalSupply)
            return false;  

        if (!TokenInterface(TheDAO).transferFrom(msg.sender, this, _amount))
            return false;  

        balances[msg.sender] += _amount;
        totalSupply += _amount;

        Mint(msg.sender, _amount, _lulz);
        return true;
    }

     
    function transfer(address _to, uint256 _amount)
    returns (bool success) {
        if (balances[_to] + _amount <= balances[_to])
            return false;  

        if (balances[msg.sender] < _amount)
            return false;  

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        Transfer(msg.sender, _to, _amount);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount)
    returns (bool success) {
        if (balances[_to] + _amount <= balances[_to])
            return false;  

        if (allowed[_from][msg.sender] < _amount)
            return false;  

        if (balances[msg.sender] < _amount)
            return false;  

        balances[_to] += _amount;
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;

        Transfer(_from, _to, _amount);
        return true;
    }

     
    function balanceOf(address _owner)
    constant
    returns (uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _amount)
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender)
    constant
    returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}