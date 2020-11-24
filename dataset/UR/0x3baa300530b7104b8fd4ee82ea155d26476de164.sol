 

pragma solidity ^0.4.21;


contract Platform
{
    address public platform = 0x709a0A8deB88A2d19DAB2492F669ef26Fd176f6C;

    modifier onlyPlatform() {
        require(msg.sender == platform);
        _;
    }

    function isPlatform() public view returns (bool) {
        return platform == msg.sender;
    }
}


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
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



contract BeneficiaryInterface
{
    function getAvailableWithdrawInvestmentsForBeneficiary() public view returns (uint);
    function withdrawInvestmentsBeneficiary(address withdraw_address) public returns (bool);
}


 
 
contract CNRAddBalanceInterface
{
    function addTokenBalance(address, uint) public;
}


 
contract CNRAddTokenInterface
{
    function addTokenAddress(address) public;
}

 
contract CNRToken is ERC20, CNRAddBalanceInterface, CNRAddTokenInterface, Platform
{
    using SafeMath for uint256;


     
    string public constant name = "ICO Constructor token";
    string public constant symbol = "CNR";
    uint256 public constant decimals = 18;


     
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => uint256) balances;
     

     
    address public grand_factory = address(0);

     
     
    mapping(address => uint256) public  tokens_map;
    TokenInfo[] public                  tokens_arr;

     
     
    mapping(address => mapping(uint => uint)) withdrawns;

    function CNRToken() public
    {
        totalSupply = 10*1000*1000*(10**decimals);  
        balances[msg.sender] = totalSupply;

         
        tokens_arr.push(
            TokenInfo(
                address(0),
                0));
    }


     
    function getRegisteredTokens()
    public view
    returns (address[])
    {
         
         
        if (tokens_arr.length <= 1)
            return;

        address[] memory token_addresses = new address[](tokens_arr.length-1);
        for (uint i = 1; i < tokens_arr.length; i++)
        {
            token_addresses[i-1] = tokens_arr[i].contract_address;
        }

        return token_addresses;
    }

     
     
     
    function getAvailableEtherCommissions()
    public view
    returns(
        address[],
        uint[]
    )
    {
         
         
        if (tokens_arr.length <= 1)
            return;

        address[] memory token_addresses = new address[](tokens_arr.length-1);
        uint[] memory available_withdraws = new uint[](tokens_arr.length-1);
         
        for (uint i = 1; i < tokens_arr.length; i++)
        {
            token_addresses[i-1] = tokens_arr[i].contract_address;
            available_withdraws[i-1] =
                BeneficiaryInterface(tokens_arr[i].contract_address).getAvailableWithdrawInvestmentsForBeneficiary();
        }

        return (token_addresses, available_withdraws);
    }


     
     
    function takeICOInvestmentsEtherCommission(address ico_token_address)
    public
    {
         
        require(tokens_map[ico_token_address] != 0);

         
        uint available_investments_commission =
            BeneficiaryInterface(ico_token_address).getAvailableWithdrawInvestmentsForBeneficiary();

         
         
        tokens_arr[0].ever_added = tokens_arr[0].ever_added.add(available_investments_commission);

         
        BeneficiaryInterface(ico_token_address).withdrawInvestmentsBeneficiary(
            address(this));
    }


     
    function()
    public payable
    {

    }


     
    function setGrandFactory(address _grand_factory)
    public
        onlyPlatform
    {
         
        require(_grand_factory != address(0));

        grand_factory = _grand_factory;
    }

     
     
     
     
     
    function balanceOfToken(address _owner, address _token_address)
    public view
    returns (uint256 balance)
    {
         
        require(tokens_map[_token_address] != 0);

        uint idx = tokens_map[_token_address];
        balance =
            tokens_arr[idx].ever_added
            .mul(balances[_owner])
            .div(totalSupply)
            .sub(withdrawns[_owner][idx]);
        }

     
     
    function balanceOfETH(address _owner)
    public view
    returns (uint256 balance)
    {
        balance =
            tokens_arr[0].ever_added
            .mul(balances[_owner])
            .div(totalSupply)
            .sub(withdrawns[_owner][0]);
    }

     
    function withdrawTokens(address _token_address, address _destination_address)
    public
    {
         
        require(tokens_map[_token_address] != 0);

        uint token_balance = balanceOfToken(msg.sender, _token_address);
        uint token_idx = tokens_map[_token_address];
        withdrawns[msg.sender][token_idx] = withdrawns[msg.sender][token_idx].add(token_balance);
        ERC20Basic(_token_address).transfer(_destination_address, token_balance);
    }

     
    function withdrawETH(address _destination_address)
    public
    {
        uint value_in_wei = balanceOfETH(msg.sender);
        withdrawns[msg.sender][0] = withdrawns[msg.sender][0].add(value_in_wei);
        _destination_address.transfer(value_in_wei);
    }


     
     
    function addTokenBalance(address _token_contract, uint amount)
    public
    {
         
        require(tokens_map[msg.sender] != 0);

         
        tokens_arr[tokens_map[_token_contract]].ever_added = tokens_arr[tokens_map[_token_contract]].ever_added.add(amount);
    }

     
     
    function addTokenAddress(address ico_token_address)
    public
    {
         
        require(grand_factory == msg.sender);

         
        require(tokens_map[ico_token_address] == 0);

        tokens_arr.push(
            TokenInfo(
                ico_token_address,
                0));
        tokens_map[ico_token_address] = tokens_arr.length - 1;
    }



     

     
    function balanceOf(address _owner)
    public view
    returns (uint256 balance)
    {
        return balances[_owner];
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         

        for (uint i = 0; i < tokens_arr.length; i++)
        {
             
            uint withdraw_to_transfer = withdrawns[msg.sender][i].mul(_value).div(balances[msg.sender]);

             
            withdrawns[msg.sender][i] = withdrawns[msg.sender][i].sub(withdraw_to_transfer);
            withdrawns[_to][i] = withdrawns[_to][i].add(withdraw_to_transfer);
        }


         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);


         
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        for (uint i = 0; i < tokens_arr.length; i++)
        {
             
            uint withdraw_to_transfer = withdrawns[_from][i].mul(_value).div(balances[_from]);

             
            withdrawns[_from][i] = withdrawns[_from][i].sub(withdraw_to_transfer);
            withdrawns[_to][i] = withdrawns[_to][i].add(withdraw_to_transfer);
        }


        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);


        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
     

    struct TokenInfo
    {
         
        address contract_address;

         
         
        uint256 ever_added;
    }
}