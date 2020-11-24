 

pragma solidity 0.4.22;
 

 
interface ERC20
{
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

}

 
contract StandardToken is ERC20
{
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        if (!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {
            revert();
        }

        return true;

    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance)
    {
        return balances[_owner];

    }

    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }

        return false;

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        }

        return false;

    }

    function totalSupply() public view returns (uint256 supply) 
    {
        return totalSupply;

    }
    
}

 
contract Zigilua is StandardToken
{
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'Z1';
    address public zigWallet;

    uint256 private _usd;
    uint8 private _crrStage;
    uint private _minUSDrequired;
    uint8[] public ZIGS_BY_STAGE = [
                                    1,
                                    1,
                                    3,
                                    5
                                   ];


     
    function Zigilua() public
    {
        balances[msg.sender] = 79700000000;
        totalSupply          = 79700000000;
        name                 = "ZigiLua";
        decimals             = 0;
        symbol               = "ZGL";
        zigWallet            = msg.sender;

        _crrStage            = 0;
        _minUSDrequired      = 200;
        _usd                 = 50000;
    }


     
    function () public payable
    {
        buy(msg.value);

    }


     
    function buy(uint256 wai) public payable returns (uint256[5])
    {
        uint256 amount = ((wai * _usd * 10 * ZIGS_BY_STAGE[_crrStage]) / (1e18));

        require(balances[zigWallet] >= amount);
        require(amount >= (2000 * (1 / ZIGS_BY_STAGE[_crrStage])));

        balances[zigWallet]  = (balances[zigWallet] - amount);
        balances[msg.sender] = (balances[msg.sender] + amount);

        emit Transfer(zigWallet, msg.sender, amount);

        zigWallet.transfer(msg.value);

        return ([wai, _usd, amount, balances[zigWallet], balances[msg.sender]]);

    }


     
    function getBalanceFromOwner() public view returns (uint256)
    {
        return balances[zigWallet];

    }


     
    function getBalanceFrom(address from) public view returns (uint256)
    {
        return balances[from];

    }


     
    function getUSD() public view returns (uint256)
    {
        return _usd;

    }


     
    function getStage() public view returns (uint256)
    {
        return _crrStage;

    }
    
     
    function setStage(uint8 stage) public returns (bool)
    {
        require(msg.sender == zigWallet);

        _crrStage = stage;

        return true;

    }


     
    function setUSD(uint256 usd) public returns (bool)
    {
        require(msg.sender == zigWallet);
        require(usd > 0);
        _usd = usd;

        return true;

    }


}