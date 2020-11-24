 

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ShareToken {
     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    address public corporationContract;
    mapping (address => bool) public identityApproved;
    mapping (address => bool) public voteLock;  

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
     
     

    uint256 public transferCount = 0;


    struct pasttransfer {
      address  from;
      address  to;
      uint256 beforesender;
      uint256 beforereceiver;
      uint256 value;
      uint256 time;
    }

    pasttransfer[] transfers;

    modifier onlyCorp() {
        require(msg.sender == corporationContract);
        _;
    }
     
    function ShareToken() {

    }

    function init(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol, address _owner) {
      corporationContract = msg.sender;
      balanceOf[_owner] = initialSupply;                      
      identityApproved[_owner] = true;
      totalSupply = initialSupply;                         
      allowance[_owner][corporationContract] = (totalSupply - 1);    
      name = tokenName;                                    
      symbol = tokenSymbol;                                
      decimals = decimalUnits;                             
    }

    function approveMember(address _newMember) public  returns (bool) {
        identityApproved[_newMember] = true;
        return true;
    }

    function Transfer(address from, address to, uint256 beforesender, uint256 beforereceiver, uint256 value, uint256 time) {
      transferCount++;
      pasttransfer memory t;
      t.from = from;
      t.to = to;
      t.beforesender = beforesender;
      t.beforereceiver = beforereceiver;
      t.value = value;
      t.time = time;
      transfers.push(t);
    }

     
     
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < (_value + 1)) revert();            
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  
        require(identityApproved[_to]);
        uint256 receiver = balanceOf[_to];
        uint256 sender = balanceOf[msg.sender];
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, sender, receiver, _value, now);                    
    }
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balanceOf[_from] < (_value + 1)) revert();                  
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();   
        if (_value > allowance[_from][msg.sender]) revert();    
        require(identityApproved[_to]);
        uint256 receiver = balanceOf[_to];
        uint256 sender = balanceOf[_from];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to,sender, receiver, _value, now);
        return true;
    }
     
    function () {
        revert();      
    }

    function isApproved(address _user) constant returns (bool) {
        return identityApproved[_user];
    }

    function getTransferCount() public view returns (uint256 count) {
      return transferCount;
    }

    function getTransfer(uint256 i) public view returns (address from, address to, uint256 beforesender, uint256 beforereceiver, uint256 value, uint256 time) {
      pasttransfer memory t = transfers[i];
      return (t.from, t.to, t.beforesender, t.beforereceiver, t.value, t.time);
    }

     
    function getBalance(address _owner) public view returns (uint256 balance) {
      return balanceOf[_owner];
    }
}