 

pragma solidity ^0.4.18;

 
contract OwnableToken
{
    address owner;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function OwnableToken() public payable {
        owner = msg.sender;
    }

    function changeOwner(address _new_owner) payable public onlyOwner {
        require(_new_owner != address(0));
        owner = _new_owner;
    }
}

 
contract ERC20I
{
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract ERC20 is ERC20I {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public
        returns (bool success)
    {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool success)
    {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}

 
contract ANtokContractAirdrop is ERC20, OwnableToken
{
    event Wasted(address to, uint256 value, uint256 date);   

    string public version = '1.2';  

    uint8  public decimals;
    string public name;
    string public symbol;   

    uint256 public paySize = 1 * 10 ** 18;   
    uint256 public holdersCount;
    uint256 public tokensSpent;

    mapping (address => bool) bounty;  

     
    function ANtokContractAirdrop() public payable {
        decimals = 18;   
        name = "ALFA NTOK";   
        symbol = "аNTOK";   
        balances[msg.sender] = 20180000 * 10 ** uint(decimals);  
        balances[this] = 50000 * 10 ** uint(decimals);  
        totalSupply = balances[msg.sender] + balances[this];  
    }

     
    function massTransfer(address [] _holders) public onlyOwner {

        uint256 count = _holders.length;
        assert(paySize * count <= balanceOf(msg.sender));
        for (uint256 i = 0; i < count; i++) {
            transfer(_holders [i], paySize);
        }
        Wasted(owner, tokensSpent, now);
    }

     
    function withdrawTo(address _recipient, uint256 _amount) public onlyOwner {
        this.transfer(_recipient, _amount);
    }

     
    function setPaySize(uint256 _value) public onlyOwner
        returns (uint256)
    {
        paySize = _value;
        return paySize;
    }

     
    function withdrawBounty(address _recipient, uint256 _amount) internal {
        this.transfer(_recipient, _amount);
    }

     
    function getBounty() public payable {
        require(bounty[msg.sender] != true);  
        require(balances[this] != 0);
        bounty[msg.sender] = true;
        withdrawBounty(msg.sender, 1 * 10 ** uint(decimals));
    }

     
    function bountyOf(address _bountist) view public
        returns (bool thanked)
    {
        return bounty[_bountist];
    }

    function() public {
        revert();  
    }
}