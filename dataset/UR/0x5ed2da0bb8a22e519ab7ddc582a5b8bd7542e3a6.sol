 

pragma solidity ^0.5.0;


library SafeMath {



    uint256 constant internal MAX_UINT = 2 ** 256 - 1;  



     

    function mul(uint256 _a, uint256 _b) internal pure returns(uint256) {

        if (_a == 0) {

            return 0;

        }

        require(MAX_UINT / _a >= _b);

        return _a * _b;

    }



     

    function div(uint256 _a, uint256 _b) internal pure returns(uint256) {

        require(_b != 0);

        return _a / _b;

    }



     

    function sub(uint256 _a, uint256 _b) internal pure returns(uint256) {

        require(_b <= _a);

        return _a - _b;

    }



     

    function add(uint256 _a, uint256 _b) internal pure returns(uint256) {

        require(MAX_UINT - _a >= _b);

        return _a + _b;

    }



}





contract Ownable {

    address public owner;



    event OwnershipTransferred(

        address indexed previousOwner,

        address indexed newOwner

    );



     

    modifier onlyOwner() {

        require(msg.sender == owner);

        _;

    }



     

    function transferOwnership(address _newOwner) public onlyOwner {

        _transferOwnership(_newOwner);

    }



     

    function _transferOwnership(address _newOwner) internal {

        require(_newOwner != address(0));

        emit OwnershipTransferred(owner, _newOwner);

        owner = _newOwner;

    }

}





contract Pausable is Ownable {

    event Pause();

    event Unpause();



    bool public paused = false;



     

    modifier whenNotPaused() {

        require(!paused);

        _;

    }



     

    modifier whenPaused() {

        require(paused);

        _;

    }



     

    function pause() public onlyOwner whenNotPaused {

        paused = true;

        emit Pause();

    }



     

    function unpause() public onlyOwner whenPaused {

        paused = false;

        emit Unpause();

    }

}





contract StandardToken {

    using SafeMath for uint256;



    mapping(address => uint256) internal balances;



    mapping(address => mapping(address => uint256)) internal allowed;



    uint256 internal totalSupply_;



    event Transfer(

        address indexed from,

        address indexed to,

        uint256 value

    );



    event Approval(

        address indexed owner,

        address indexed spender,

        uint256 vaule

    );



     

    function totalSupply() public view returns(uint256) {

        return totalSupply_;

    }



     

    function balanceOf(address _owner) public view returns(uint256) {

        return balances[_owner];

    }



     

    function allowance(

        address _owner,

        address _spender

    )

    public

    view

    returns(uint256) {

        return allowed[_owner][_spender];

    }



     

    function transfer(address _to, uint256 _value) public returns(bool) {

        require(_to != address(0));

        require(_value <= balances[msg.sender]);



        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;

    }



     

    function approve(address _spender, uint256 _value) public returns(bool) {

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }



     

    function transferFrom(

        address _from,

        address _to,

        uint256 _value

    )

    public

    returns(bool) {

        require(_to != address(0));

        require(_value <= balances[_from]);

        require(_value <= allowed[_from][msg.sender]);



        balances[_from] = balances[_from].sub(_value);

        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;

    }



     

    function increaseApproval(

        address _spender,

        uint256 _addedValue

    )

    public

    returns(bool) {

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }



     

    function decreaseApproval(

        address _spender,

        uint256 _subtractedValue

    )

    public

    returns(bool) {

        uint256 oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue >= oldValue) {

            allowed[msg.sender][_spender] = 0;

        } else {

            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }



    function _burn(address account, uint256 value) internal {

        require(account != address(0));

        totalSupply_ = totalSupply_.sub(value);

        balances[account] = balances[account].sub(value);

        emit Transfer(account, address(0), value);

    }



     

    function _burnFrom(address account, uint256 value) internal {

         

         

        allowed[account][msg.sender] = allowed[account][msg.sender].sub(value);

        _burn(account, value);

    }



}





contract BurnableToken is StandardToken {



     

    function burn(uint256 value) public {

        _burn(msg.sender, value);

    }



     

    function burnFrom(address from, uint256 value) public {

        _burnFrom(from, value);

    }

}





contract PausableToken is StandardToken, Pausable {



    function transfer(

        address _to,

        uint256 _value

    )

    public

    whenNotPaused

    returns(bool) {

        return super.transfer(_to, _value);

    }



    function transferFrom(

        address _from,

        address _to,

        uint256 _value

    )

    public

    whenNotPaused

    returns(bool) {

        return super.transferFrom(_from, _to, _value);

    }



    function approve(

        address _spender,

        uint256 _value

    )

    public

    whenNotPaused

    returns(bool) {

        return super.approve(_spender, _value);

    }



    function increaseApproval(

        address _spender,

        uint _addedValue

    )

    public

    whenNotPaused

    returns(bool success) {

        return super.increaseApproval(_spender, _addedValue);

    }



    function decreaseApproval(

        address _spender,

        uint _subtractedValue

    )

    public

    whenNotPaused

    returns(bool success) {

        return super.decreaseApproval(_spender, _subtractedValue);

    }

}





contract TestToken is PausableToken, BurnableToken {

    string public name;  

    string public symbol;  

    uint8 public decimals;



    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _INIT_TOTALSUPPLY, address _owner) public {

        require(_owner != address(0));

        totalSupply_ = _INIT_TOTALSUPPLY * 10 ** uint256(_decimals);

        balances[_owner] = totalSupply_;

        name = _name;

        symbol = _symbol;

        decimals = _decimals;

        owner = _owner;
        
        emit Transfer(address(0), owner, totalSupply_);

    }

}