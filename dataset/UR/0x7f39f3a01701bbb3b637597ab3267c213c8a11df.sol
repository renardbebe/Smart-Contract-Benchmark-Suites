 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract AuthenticationManager {
     
    mapping (address => bool) adminAddresses;

     
    mapping (address => bool) accountReaderAddresses;

     
    address[] adminAudit;

     
    address[] accountReaderAudit;

     
    event AdminAdded(address addedBy, address admin);

     
    event AdminRemoved(address removedBy, address admin);

     
    event AccountReaderAdded(address addedBy, address account);

     
    event AccountReaderRemoved(address removedBy, address account);

         
    function AuthenticationManager() {
         
        adminAddresses[msg.sender] = true;
        AdminAdded(0, msg.sender);
        adminAudit.length++;
        adminAudit[adminAudit.length - 1] = msg.sender;
    }

     
    function contractVersion() constant returns(uint256) {
         
        return 100201707171503;
    }

     
    function isCurrentAdmin(address _address) constant returns (bool) {
        return adminAddresses[_address];
    }

     
    function isCurrentOrPastAdmin(address _address) constant returns (bool) {
        for (uint256 i = 0; i < adminAudit.length; i++)
            if (adminAudit[i] == _address)
                return true;
        return false;
    }

     
    function isCurrentAccountReader(address _address) constant returns (bool) {
        return accountReaderAddresses[_address];
    }

     
    function isCurrentOrPastAccountReader(address _address) constant returns (bool) {
        for (uint256 i = 0; i < accountReaderAudit.length; i++)
            if (accountReaderAudit[i] == _address)
                return true;
        return false;
    }

     
    function addAdmin(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (adminAddresses[_address])
            throw;
        
         
        adminAddresses[_address] = true;
        AdminAdded(msg.sender, _address);
        adminAudit.length++;
        adminAudit[adminAudit.length - 1] = _address;
    }

     
    function removeAdmin(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (_address == msg.sender)
            throw;

         
        if (!adminAddresses[_address])
            throw;

         
        adminAddresses[_address] = false;
        AdminRemoved(msg.sender, _address);
    }

     
    function addAccountReader(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (accountReaderAddresses[_address])
            throw;
        
         
        accountReaderAddresses[_address] = true;
        AccountReaderAdded(msg.sender, _address);
        accountReaderAudit.length++;
        accountReaderAudit[adminAudit.length - 1] = _address;
    }

     
    function removeAccountReader(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (!accountReaderAddresses[_address])
            throw;

         
        accountReaderAddresses[_address] = false;
        AccountReaderRemoved(msg.sender, _address);
    }
}
contract VotingBase {
    using SafeMath for uint256;

     
    mapping (address => uint256) public voteCount;

     
    address[] public voterAddresses;

     
    AuthenticationManager internal authenticationManager;

     
    uint256 public voteStartTime;

     
    uint256 public voteEndTime;

     
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) throw;
        _;
    }

    function setVoterCount(uint256 _count) adminOnly {
         
        if (now >= voteStartTime)
            throw;

         
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            address voter = voterAddresses[i];
            voteCount[voter] = 0;
        }

         
        voterAddresses.length = _count;
    }

    function setVoter(uint256 _position, address _voter, uint256 _voteCount) adminOnly {
         
        if (now >= voteStartTime)
            throw;

        if (_position >= voterAddresses.length)
            throw;
            
        voterAddresses[_position] = _voter;
        voteCount[_voter] = _voteCount;
    }
}

contract VoteSvp002 is VotingBase {
    using SafeMath for uint256;

     
     mapping (address => uint256) vote01;
     uint256 public vote01YesCount;
     uint256 public vote01NoCount;

     
     mapping (address => uint256) vote02;
     uint256 public vote02YesCount;
     uint256 public vote02NoCount;

     
     mapping (address => uint256) vote03;
     uint256 public vote03YesCount;
     uint256 public vote03NoCount;

     
    function VoteSvp002(address _authenticationManagerAddress, uint256 _voteStartTime, uint256 _voteEndTime) {
         
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
        if (authenticationManager.contractVersion() != 100201707171503)
            throw;

         
        if (_voteStartTime >= _voteEndTime)
            throw;
        voteStartTime = _voteStartTime;
        voteEndTime = _voteEndTime;
    }

     function voteSvp01(bool vote) {
         
        if (now < voteStartTime || now > voteEndTime)
            throw;

          
         uint256 voteWeight = voteCount[msg.sender];
         if (voteWeight == 0)
            throw;
        
         
        uint256 existingVote = vote01[msg.sender];
        uint256 newVote = vote ? 1 : 2;
        if (newVote == existingVote)
             
            return;
        vote01[msg.sender] = newVote;

         
        if (existingVote == 1)
            vote01YesCount -= voteWeight;
        else if (existingVote == 2)
            vote01NoCount -= voteWeight;
        if (vote)
            vote01YesCount += voteWeight;
        else
            vote01NoCount += voteWeight;
     }

     function voteSvp02(bool vote) {
         
        if (now < voteStartTime || now > voteEndTime)
            throw;

          
         uint256 voteWeight = voteCount[msg.sender];
         if (voteWeight == 0)
            throw;
        
         
        uint256 existingVote = vote02[msg.sender];
        uint256 newVote = vote ? 1 : 2;
        if (newVote == existingVote)
             
            return;
        vote02[msg.sender] = newVote;

         
        if (existingVote == 1)
            vote02YesCount -= voteWeight;
        else if (existingVote == 2)
            vote02NoCount -= voteWeight;
        if (vote)
            vote02YesCount += voteWeight;
        else
            vote02NoCount += voteWeight;
     }

     function voteSvp03(bool vote) {
         
        if (now < voteStartTime || now > voteEndTime)
            throw;

          
         uint256 voteWeight = voteCount[msg.sender];
         if (voteWeight == 0)
            throw;
        
         
        uint256 existingVote = vote03[msg.sender];
        uint256 newVote = vote ? 1 : 2;
        if (newVote == existingVote)
             
            return;
        vote03[msg.sender] = newVote;

         
        if (existingVote == 1)
            vote03YesCount -= voteWeight;
        else if (existingVote == 2)
            vote03NoCount -= voteWeight;
        if (vote)
            vote03YesCount += voteWeight;
        else
            vote03NoCount += voteWeight;
     }
}