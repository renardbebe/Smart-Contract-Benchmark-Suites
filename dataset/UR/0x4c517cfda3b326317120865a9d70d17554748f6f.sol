 

pragma solidity ^0.4.24;

 
 
 
contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

  
  
  
  
  
contract LOTS is EIP20Interface {
    using SafeMath for uint;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public constant name = "LOTS Token";                 
    uint8 public constant decimals = 18;     
    string public constant symbol = "LOTS";                 
    uint public constant finalSupply = 10**9 * 10**uint(decimals);  
    uint public totalSupply;   

     
    uint public constant fundraisingReservation = 50 * finalSupply / 100;
    uint public constant foundationReservation = 5 * finalSupply / 100;
    uint public constant communityReservation = 25 * finalSupply / 100;
    uint public constant teamReservation = 20 * finalSupply / 100;

     
     
    uint public nextWithdrawDayFoundation;
    uint public nextWithdrawDayCommunity;
    uint public nextWithdrawDayTeam;

    uint public withdrawedFundrasingPart;  
    uint public withdrawedFoundationCounter;   
    uint public withdrawedCoummunityCounter;   
    uint public withdrawedTeamCounter;   
    
    address public manager;  
    bool public paused;  

    event Burn(address _from, uint _value);

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    modifier notPaused() {
        require(paused == false);
        _;
    }

    constructor() public {
        manager = msg.sender;
        nextWithdrawDayFoundation = now;
        nextWithdrawDayCommunity = now;
        nextWithdrawDayTeam = now;
    }

     
    function pause() public onlyManager() {
        paused = !paused;
    }

    function withdrawFundraisingPart(address _to, uint _value) public onlyManager() {
        require(_value.add(withdrawedFundrasingPart) <= fundraisingReservation);
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        withdrawedFundrasingPart = withdrawedFundrasingPart.add(_value);
        emit Transfer(address(this), _to, _value);
    }

    function withdrawFoundationPart(address _to) public onlyManager() {
        require(now > nextWithdrawDayFoundation);
        require(withdrawedFoundationCounter < 48);
        balances[_to] = balances[_to].add(foundationReservation / 48);
        withdrawedFoundationCounter += 1;
        nextWithdrawDayFoundation += 30 days;
        totalSupply = totalSupply.add(foundationReservation / 48);
        emit Transfer(address(this), _to, foundationReservation / 48);
    }

    function withdrawCommunityPart(address _to) public onlyManager() {
        require(now > nextWithdrawDayCommunity);
        uint _value;
        if (withdrawedCoummunityCounter == 0) {
            _value = communityReservation / 2;
        } else if (withdrawedCoummunityCounter == 1) {
            _value = communityReservation * 3 / 10;
        } else if (withdrawedCoummunityCounter == 2 || withdrawedCoummunityCounter == 3) {
            _value = communityReservation / 10;
        } else {
            return;
        }
        balances[_to] = balances[_to].add(_value);
        withdrawedCoummunityCounter += 1;
        nextWithdrawDayCommunity += 365 days;
        totalSupply = totalSupply.add(_value);
        emit Transfer(address(this), _to, _value);
    }

    function withdrawTeam(address _to) public onlyManager() {
        require(now > nextWithdrawDayTeam);
        require(withdrawedTeamCounter < 48);
        balances[_to] = balances[_to].add(teamReservation / 48);
        withdrawedTeamCounter += 1;
        nextWithdrawDayTeam += 30 days;
        totalSupply = totalSupply.add(teamReservation / 48);
        emit Transfer(address(this), _to, teamReservation / 48);
    }

     
    function burn(uint _value) public returns (bool success) {
        totalSupply = totalSupply.sub(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns(bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue){
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        return true;
    }
    
     

    function transfer(address _to, uint _value) public notPaused() returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public notPaused() returns (bool success) {
        uint allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}