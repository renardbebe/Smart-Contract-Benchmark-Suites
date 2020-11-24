 

pragma solidity ^0.4;


contract ERC20 {
    uint public totalSupply;
    function balanceOf(address _account) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract Token is ERC20 {
     
     
    mapping(address => uint256) public balances;
    mapping(address => uint256) public FreezeBalances;
    mapping(address => mapping (address => uint)) allowed;

     
    uint256 public totalSupply;
    uint256 public preSaleSupply;
    uint256 public ICOSupply;
    uint256 public userGrowsPoolSupply;
    uint256 public auditSupply;
    uint256 public bountySupply;

     
    uint256 public totalTokensRemind;

     
    string public constant name = "AdMine";
    string public constant symbol = "MCN";
    address public owner;
    uint8 public decimals = 5;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    uint public unfreezeTime;
    uint public AdmineTeamTokens;
    uint public AdmineAdvisorTokens;


    function Token() public {
        owner = msg.sender;
         
         
        totalSupply = 10000000000000;

         
        preSaleSupply = totalSupply * 5 / 100;

         
        ICOSupply = totalSupply * 60 / 100;

         
        userGrowsPoolSupply = totalSupply * 10 / 100;

         
        AdmineTeamTokens = totalSupply * 15 / 100;

         
        AdmineAdvisorTokens = totalSupply * 6 / 100;

         
        auditSupply = totalSupply * 2 / 100;

         
        bountySupply = totalSupply * 2 / 100;

        totalTokensRemind = totalSupply;
        balances[owner] = totalSupply;
        unfreezeTime = now + 1 years;

        freeze(0x01306bfbC0C20BEADeEc30000F634d08985D87de, AdmineTeamTokens);
    }

     
    function transferAuditTokens(address _to, uint256 _amount) public onlyOwner {
        require(auditSupply>=_amount);
        balances[owner] -= _amount;
        balances[_to] += _amount;
        auditSupply -= _amount;
        totalTokensRemind -= _amount;
    }

     
    function transferBountyTokens(address _to, uint256 _amount) public onlyOwner {
        require(bountySupply>=_amount);
        balances[owner] -= _amount;
        balances[_to] += _amount;
        bountySupply -= _amount;
        totalTokensRemind -= _amount;
    }

    function returnBountyTokens(address _from, uint256 _amount) public onlyOwner {
        require(balances[_from]>=_amount);
        balances[owner] += _amount;
        balances[_from] -= _amount;
        bountySupply += _amount;
        totalTokensRemind += _amount;
    }

     
    function transferUserGrowthPoolTokens(address _to, uint256 _amount) public onlyOwner {
        require(userGrowsPoolSupply>=_amount);
        balances[owner] -= _amount;
        balances[_to] += _amount;
        userGrowsPoolSupply -= _amount;
        totalTokensRemind -= _amount;
    }

    function returnUserGrowthPoolTokens(address _from, uint256 _amount) public onlyOwner {
        require(balances[_from]>=_amount);
        balances[owner] += _amount;
        balances[_from] -= _amount;
        userGrowsPoolSupply += _amount;
        totalTokensRemind += _amount;
    }

     
    function transferAdvisorTokens(address _to, uint256 _amount) public onlyOwner {
        require(AdmineAdvisorTokens>=_amount);
        balances[owner] -= _amount;
        balances[_to] += _amount;
        AdmineAdvisorTokens -= _amount;
        totalTokensRemind -= _amount;
    }

    function returnAdvisorTokens(address _from, uint256 _amount) public onlyOwner {
        require(balances[_from]>=_amount);
        balances[owner] += _amount;
        balances[_from] -= _amount;
        AdmineAdvisorTokens += _amount;
        totalTokensRemind += _amount;
    }

     
    function transferIcoTokens(address _to, uint256 _amount) public onlyOwner {
        require(ICOSupply>=_amount);
        balances[owner] -= _amount;
        balances[_to] += _amount;
        ICOSupply -= _amount;
        totalTokensRemind -= _amount;
    }

    function returnIcoTokens(address _from, uint256 _amount) public onlyOwner {
        require(balances[_from]>=_amount);
        balances[owner] += _amount;
        balances[_from] -= _amount;
        ICOSupply += _amount;
        totalTokensRemind += _amount;
    }

     
    function transferPreSaleTokens(address _to, uint256 _amount) public onlyOwner {
        require(preSaleSupply>=_amount);
        balances[owner] -= _amount;
        balances[_to] += _amount;
        preSaleSupply -= _amount;
        totalTokensRemind -= _amount;
    }

    function returnPreSaleTokens(address _from, uint256 _amount) public onlyOwner {
        require(balances[_from]>=_amount);
        balances[owner] += _amount;
        balances[_from] -= _amount;
        preSaleSupply += _amount;
        totalTokensRemind += _amount;
    }

     
    function eraseUnsoldPreSaleTokens() public onlyOwner {
        balances[owner] -= preSaleSupply;
        preSaleSupply = 0;
        totalTokensRemind -= preSaleSupply;
    }

    function transferUserTokensTo(address _from, address _to, uint256 _amount) public onlyOwner {
        require(balances[_from] >= _amount && _amount > 0);
        balances[_from] -= _amount;
        balances[_to] += _amount;
        Transfer(_from, _to, _amount);
    }

     
    function balanceOf(address _account) public constant returns (uint256 balance) {
        return balances[_account];
    }

     
    function transfer(address _to, uint _value) public  returns (bool success) {
        require(_to != 0x0);                                
        require(balances[msg.sender] >= _value);            
        balances[msg.sender] -= _value;                     
        balances[_to] += _value;                            
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public  returns(bool) {
        require(_amount <= allowed[_from][msg.sender]);
        if (balances[_from] >= _amount && _amount > 0) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            allowed[_from][msg.sender] -= _amount;
            Transfer(_from, _to, _amount);
            return true;
        }
        else {
            return false;
        }
    }

    function approve(address _spender, uint _value) public  returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function add_tokens(address _to, uint256 _amount) public onlyOwner {
        balances[owner] -= _amount;
        balances[_to] += _amount;
        totalTokensRemind -= _amount;
    }


     
    function all_unfreeze() public onlyOwner {
        require(now >= unfreezeTime);
         
        unfreeze(0x01306bfbC0C20BEADeEc30000F634d08985D87de);
    }

    function unfreeze(address _user) internal {
        uint amount = FreezeBalances[_user];
        balances[_user] += amount;
    }


    function freeze(address _user, uint256 _amount) public onlyOwner {
        balances[owner] -= _amount;
        FreezeBalances[_user] += _amount;

    }

}