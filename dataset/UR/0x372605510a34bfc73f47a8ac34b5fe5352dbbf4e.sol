 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}







 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
contract ValorTimelock{


    event EmergencyRelease(
        address from,
        address to,
        uint256 value
    );

     
    ERC20 public token;

     
    address public beneficiary;

     
    uint256 public releaseTime;

     
    address public owner;

     
    constructor(ERC20 _token, address _beneficiary, address _admin, uint256 _duration )
    public {
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = block.timestamp + _duration; 
        owner = _admin;
    }


     
    function release() external {
        uint256 balance = token.balanceOf(address(this));
        partialRelease(balance);
    }

     
    function partialRelease(uint256 _amount) public {

         
         
         
        require(block.timestamp >= releaseTime);

        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount);
        require(_amount > 0);

        require(token.transfer(beneficiary, _amount));
    }


     
    function emergencyRelease() external{
        require(msg.sender == owner);
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0);
        require(token.transfer(beneficiary, amount));
        emit EmergencyRelease(msg.sender, beneficiary, amount);
    }

}