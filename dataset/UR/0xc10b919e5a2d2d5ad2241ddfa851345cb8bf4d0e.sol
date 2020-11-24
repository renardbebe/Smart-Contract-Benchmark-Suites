 

pragma solidity ^0.4.21;

contract Zamok {

     
    uint256 public zamokCount;

     
    function Zamok() public {
        zamokCount = 0;
    }

     
    function generateZamokId() internal returns (bytes32 zamokId) {
        return keccak256(block.blockhash(block.number - 1), address(this), ++zamokCount);
    }
}


contract CustodianCanBeReplaced is Zamok {

     
    struct CustodianChangeRequest {
        address proposedNew;
    }

     
    address public custodian;

    mapping (bytes32 => CustodianChangeRequest) public custodianChangeRequests;

     
    function CustodianCanBeReplaced(
        address _custodian
    )
    
	Zamok() public
    {
        custodian = _custodian;
    }

     
    modifier onlyCustodian {
        require(msg.sender == custodian);
        _;
    }

     
     

    function requestCustodianChange(address _proposedCustodian) public returns (bytes32 zamokId) {
        require(_proposedCustodian != address(0));

        zamokId = generateZamokId();

        custodianChangeRequests[zamokId] = CustodianChangeRequest({
            proposedNew: _proposedCustodian
        });

        emit CustodianChangeRequested(zamokId, msg.sender, _proposedCustodian);
    }

    function confirmCustodianChange(bytes32 _zamokId) public onlyCustodian {
        custodian = getCustodianChangeRequest(_zamokId);

        delete custodianChangeRequests[_zamokId];

        emit CustodianChangeConfirmed(_zamokId, custodian);
    }

     
    function getCustodianChangeRequest(bytes32 _zamokId) private view returns (address _proposedNew) {
        CustodianChangeRequest storage changeRequest = custodianChangeRequests[_zamokId];

         
         
        require(changeRequest.proposedNew != 0);

        return changeRequest.proposedNew;
    }

    event CustodianChangeRequested(
        bytes32 _zamokId,
        address _msgSender,
        address _proposedCustodian
    );

    event CustodianChangeConfirmed(bytes32 _zamokId, address _newCustodian);
}


contract DeloCanBeReplaced is CustodianCanBeReplaced  {

     
    struct DeloChangeRequest {
        address proposedNew;
    }

     
     
    Delo public delo;

    mapping (bytes32 => DeloChangeRequest) public deloChangeRequests;

     
    function DeloCanBeReplaced(address _custodian) CustodianCanBeReplaced(_custodian) public {
        delo = Delo(0x0);
    }

     
    modifier onlyDelo {
        require(msg.sender == address(delo));
        _;
    }

     
     
    function requestDeloChange(address _proposedDelo) public returns (bytes32 zamokId) {
        require(_proposedDelo != address(0));

        zamokId = generateZamokId();

        deloChangeRequests[zamokId] = DeloChangeRequest({
            proposedNew: _proposedDelo
        });

        emit DeloChangeRequested(zamokId, msg.sender, _proposedDelo);
    }

    function confirmDeloChange(bytes32 _zamokId) public onlyCustodian {
        delo = getDeloChangeRequest(_zamokId);

        delete deloChangeRequests[_zamokId];

        emit DeloChangeConfirmed(_zamokId, address(delo));
    }

     
    function getDeloChangeRequest(bytes32 _zamokId) private view returns (Delo _proposedNew) {
        DeloChangeRequest storage changeRequest = deloChangeRequests[_zamokId];

         
         
        require(changeRequest.proposedNew != address(0));

        return Delo(changeRequest.proposedNew);
    }

    event DeloChangeRequested(
        bytes32 _zamokId,
        address _msgSender,
        address _proposedDelo
    );

    event DeloChangeConfirmed(bytes32 _zamokId, address _newImpl);
}


contract ERC20Interface {
   

   
   
   

   
   

   
   

   
   

   
  function totalSupply() public view returns (uint256);

   
  function balanceOf(address _owner) public view returns (uint256 balance);

   
  function transfer(address _to, uint256 _value) public returns (bool success);

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
  function approve(address _spender, uint256 _value) public returns (bool success);

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

   
   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Front is ERC20Interface, DeloCanBeReplaced {

     
    string public name;

    string public symbol;

    uint8 public decimals;

     
    function Front(
        string _name,
        string _symbol,
        uint8 _decimals,
        address _custodian
    )
        DeloCanBeReplaced(_custodian)
        public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
     
    function totalSupply() public view returns (uint256) {
        return delo.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return delo.balanceOf(_owner);
    }

    function emitTransfer(address _from, address _to, uint256 _value) public onlyDelo {
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        return delo.transferWithSender(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        return delo.transferFromWithSender(msg.sender, _from, _to, _value);
    }

    function emitApproval(address _owner, address _spender, uint256 _value) public onlyDelo {
        emit Approval(_owner, _spender, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        return delo.approveWithSender(msg.sender, _spender, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) {
        return delo.increaseApprovalWithSender(msg.sender, _spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) {
        return delo.decreaseApprovalWithSender(msg.sender, _spender, _subtractedValue);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return delo.allowance(_owner, _spender);
    }
}


contract Delo is CustodianCanBeReplaced {

     
    struct PendingPrint {
        address receiver;
        uint256 value;
    }

     
    Front public front;

    Grossbuch public grossbuch;

    address public sweeper;

    bytes32 public sweepMsg;

    mapping (address => bool) public sweptSet;

    mapping (bytes32 => PendingPrint) public pendingPrintMap;

     
    function Delo(
          address _front,
          address _grossbuch,
          address _custodian,
          address _sweeper
    )
        CustodianCanBeReplaced(_custodian)
        public
    {
        require(_sweeper != 0);
        front = Front(_front);
        grossbuch = Grossbuch(_grossbuch);

        sweeper = _sweeper;
        sweepMsg = keccak256(address(this), "sweep");
    }

     
    modifier onlyFront {
        require(msg.sender == address(front));
        _;
    }
    modifier onlySweeper {
        require(msg.sender == sweeper);
        _;
    }


    function approveWithSender(
        address _sender,
        address _spender,
        uint256 _value
    )
        public
        onlyFront
        returns (bool success)
    {
        require(_spender != address(0));  
        grossbuch.setAllowance(_sender, _spender, _value);
        front.emitApproval(_sender, _spender, _value);
        return true;
    }

    function increaseApprovalWithSender(
        address _sender,
        address _spender,
        uint256 _addedValue
    )
        public
        onlyFront
        returns (bool success)
    {
        require(_spender != address(0));  
        uint256 currentAllowance = grossbuch.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance + _addedValue;

        require(newAllowance >= currentAllowance);

        grossbuch.setAllowance(_sender, _spender, newAllowance);
        front.emitApproval(_sender, _spender, newAllowance);
        return true;
    }

    function decreaseApprovalWithSender(
        address _sender,
        address _spender,
        uint256 _subtractedValue
    )
        public
        onlyFront
        returns (bool success)
    {
        require(_spender != address(0));  
        uint256 currentAllowance = grossbuch.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance - _subtractedValue;

        require(newAllowance <= currentAllowance);

        grossbuch.setAllowance(_sender, _spender, newAllowance);
        front.emitApproval(_sender, _spender, newAllowance);
        return true;
    }


    function requestPrint(address _receiver, uint256 _value) public returns (bytes32 zamokId) {
        require(_receiver != address(0));

        zamokId = generateZamokId();

        pendingPrintMap[zamokId] = PendingPrint({
            receiver: _receiver,
            value: _value
        });

        emit PrintingLocked(zamokId, _receiver, _value);
    }


    function confirmPrint(bytes32 _zamokId) public onlyCustodian {
        PendingPrint storage print = pendingPrintMap[_zamokId];

         
         
        address receiver = print.receiver;
        require (receiver != address(0));
        uint256 value = print.value;

        delete pendingPrintMap[_zamokId];

        uint256 supply = grossbuch.totalSupply();
        uint256 newSupply = supply + value;
        if (newSupply >= supply) {
          grossbuch.setTotalSupply(newSupply);
          grossbuch.addBalance(receiver, value);

          emit PrintingConfirmed(_zamokId, receiver, value);
          front.emitTransfer(address(0), receiver, value);
        }
    }


    function burn(uint256 _value) public returns (bool success) {
        uint256 balanceOfSender = grossbuch.balances(msg.sender);
        require(_value <= balanceOfSender);

        grossbuch.setBalance(msg.sender, balanceOfSender - _value);
        grossbuch.setTotalSupply(grossbuch.totalSupply() - _value);

        front.emitTransfer(msg.sender, address(0), _value);

        return true;
    }


    function batchTransfer(address[] _tos, uint256[] _values) public returns (bool success) {
        require(_tos.length == _values.length);

        uint256 numTransfers = _tos.length;
        uint256 senderBalance = grossbuch.balances(msg.sender);

        for (uint256 i = 0; i < numTransfers; i++) {
          address to = _tos[i];
          require(to != address(0));
          uint256 v = _values[i];
          require(senderBalance >= v);

          if (msg.sender != to) {
            senderBalance -= v;
            grossbuch.addBalance(to, v);
          }
          front.emitTransfer(msg.sender, to, v);
        }

        grossbuch.setBalance(msg.sender, senderBalance);

        return true;
    }

    function enableSweep(uint8[] _vs, bytes32[] _rs, bytes32[] _ss, address _to) public onlySweeper {
        require(_to != address(0));
        require((_vs.length == _rs.length) && (_vs.length == _ss.length));

        uint256 numSignatures = _vs.length;
        uint256 sweptBalance = 0;

        for (uint256 i=0; i<numSignatures; ++i) {
          address from = ecrecover(sweepMsg, _vs[i], _rs[i], _ss[i]);

           
          if (from != address(0)) {
            sweptSet[from] = true;

            uint256 fromBalance = grossbuch.balances(from);

            if (fromBalance > 0) {
              sweptBalance += fromBalance;

              grossbuch.setBalance(from, 0);

              front.emitTransfer(from, _to, fromBalance);
            }
          }
        }

        if (sweptBalance > 0) {
          grossbuch.addBalance(_to, sweptBalance);
        }
    }

    function replaySweep(address[] _froms, address _to) public onlySweeper {
        require(_to != address(0));
        uint256 lenFroms = _froms.length;
        uint256 sweptBalance = 0;

        for (uint256 i=0; i<lenFroms; ++i) {
            address from = _froms[i];

            if (sweptSet[from]) {
                uint256 fromBalance = grossbuch.balances(from);

                if (fromBalance > 0) {
                    sweptBalance += fromBalance;

                    grossbuch.setBalance(from, 0);

                    front.emitTransfer(from, _to, fromBalance);
                }
            }
        }

        if (sweptBalance > 0) {
            grossbuch.addBalance(_to, sweptBalance);
        }
    }

    function transferFromWithSender(
        address _sender,
        address _from,
        address _to,
        uint256 _value
    )
        public
        onlyFront
        returns (bool success)
    {
        require(_to != address(0));  

        uint256 balanceOfFrom = grossbuch.balances(_from);
        require(_value <= balanceOfFrom);

        uint256 senderAllowance = grossbuch.allowed(_from, _sender);
        require(_value <= senderAllowance);

        grossbuch.setBalance(_from, balanceOfFrom - _value);
        grossbuch.addBalance(_to, _value);

        grossbuch.setAllowance(_from, _sender, senderAllowance - _value);

        front.emitTransfer(_from, _to, _value);

        return true;
    }

    function transferWithSender(
        address _sender,
        address _to,
        uint256 _value
    )
        public
        onlyFront
        returns (bool success)
    {
        require(_to != address(0));  

        uint256 balanceOfSender = grossbuch.balances(_sender);
        require(_value <= balanceOfSender);

        grossbuch.setBalance(_sender, balanceOfSender - _value);
        grossbuch.addBalance(_to, _value);

        front.emitTransfer(_sender, _to, _value);

        return true;
    }

     
    function totalSupply() public view returns (uint256) {
        return grossbuch.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return grossbuch.balances(_owner);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return grossbuch.allowed(_owner, _spender);
    }

     
    event PrintingLocked(bytes32 _zamokId, address _receiver, uint256 _value);

    event PrintingConfirmed(bytes32 _zamokId, address _receiver, uint256 _value);
}



contract Grossbuch is DeloCanBeReplaced {

     
    uint256 public totalSupply;

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) public allowed;

     
    function Grossbuch(address _custodian) DeloCanBeReplaced(_custodian) public {
        totalSupply = 0;
    }


     

    function setTotalSupply(
        uint256 _newTotalSupply
    )
        public
        onlyDelo
    {
        totalSupply = _newTotalSupply;
    }


    function setAllowance(
        address _owner,
        address _spender,
        uint256 _value
    )
        public
        onlyDelo
    {
        allowed[_owner][_spender] = _value;
    }


    function setBalance(
        address _owner,
        uint256 _newBalance
    )
        public
        onlyDelo
    {
        balances[_owner] = _newBalance;
    }


    function addBalance(
        address _owner,
        uint256 _balanceIncrease
    )
        public
        onlyDelo
    {
        balances[_owner] = balances[_owner] + _balanceIncrease;
    }
}