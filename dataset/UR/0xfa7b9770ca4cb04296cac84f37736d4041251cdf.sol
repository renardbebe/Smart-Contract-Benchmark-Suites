 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
contract ReleaseOracle {
   
  struct Votes {
    address[] pass;  
    address[] fail;  
  }

   
  struct Version {
    uint32  major;   
    uint32  minor;   
    uint32  patch;   
    bytes20 commit;  

    uint64  time;   
    Votes   votes;  
  }

   
  mapping(address => bool) authorised;  
  address[]                voters;      

   
  mapping(address => Votes) authProps;  
  address[]                 authPend;   

  Version   verProp;   
  Version[] releases;  

   
  modifier isSigner() {
    if (authorised[msg.sender]) {
      _
    }
  }

   
  function ReleaseOracle(address[] signers) {
     
    if (signers.length == 0) {
      authorised[msg.sender] = true;
      voters.push(msg.sender);
      return;
    }
     
    for (uint i = 0; i < signers.length; i++) {
      authorised[signers[i]] = true;
      voters.push(signers[i]);
    }
  }

   
   
  function signers() constant returns(address[]) {
    return voters;
  }

   
   
  function authProposals() constant returns(address[]) {
    return authPend;
  }

   
   
  function authVotes(address user) constant returns(address[] promote, address[] demote) {
    return (authProps[user].pass, authProps[user].fail);
  }

   
   
  function currentVersion() constant returns (uint32 major, uint32 minor, uint32 patch, bytes20 commit, uint time) {
    if (releases.length == 0) {
      return (0, 0, 0, 0, 0);
    }
    var release = releases[releases.length - 1];

    return (release.major, release.minor, release.patch, release.commit, release.time);
  }

   
   
  function proposedVersion() constant returns (uint32 major, uint32 minor, uint32 patch, bytes20 commit, address[] pass, address[] fail) {
    return (verProp.major, verProp.minor, verProp.patch, verProp.commit, verProp.votes.pass, verProp.votes.fail);
  }

   
   
  function promote(address user) {
    updateSigner(user, true);
  }

   
   
  function demote(address user) {
    updateSigner(user, false);
  }

   
  function release(uint32 major, uint32 minor, uint32 patch, bytes20 commit) {
    updateRelease(major, minor, patch, commit, true);
  }

   
   
  function nuke() {
    updateRelease(0, 0, 0, 0, false);
  }

   
   
  function updateSigner(address user, bool authorize) internal isSigner {
     
    Votes votes = authProps[user];
    for (uint i = 0; i < votes.pass.length; i++) {
      if (votes.pass[i] == msg.sender) {
        return;
      }
    }
    for (i = 0; i < votes.fail.length; i++) {
      if (votes.fail[i] == msg.sender) {
        return;
      }
    }
     
    if (votes.pass.length == 0 && votes.fail.length == 0) {
      authPend.push(user);
    }
     
    if (authorize) {
      votes.pass.push(msg.sender);
      if (votes.pass.length <= voters.length / 2) {
        return;
      }
    } else {
      votes.fail.push(msg.sender);
      if (votes.fail.length <= voters.length / 2) {
        return;
      }
    }
     
    if (authorize && !authorised[user]) {
      authorised[user] = true;
      voters.push(user);
    } else if (!authorize && authorised[user]) {
      authorised[user] = false;

      for (i = 0; i < voters.length; i++) {
        if (voters[i] == user) {
          voters[i] = voters[voters.length - 1];
          voters.length--;

          delete verProp;  
          break;
        }
      }
    }
     
    delete authProps[user];

    for (i = 0; i < authPend.length; i++) {
      if (authPend[i] == user) {
        authPend[i] = authPend[authPend.length - 1];
        authPend.length--;
        break;
      }
    }
  }

   
   
  function updateRelease(uint32 major, uint32 minor, uint32 patch, bytes20 commit, bool release) internal isSigner {
     
    if (!release && verProp.votes.pass.length == 0) {
      return;
    }
     
    if (verProp.votes.pass.length == 0) {
      verProp.major  = major;
      verProp.minor  = minor;
      verProp.patch  = patch;
      verProp.commit = commit;
    }
     
    if (release && (verProp.major != major || verProp.minor != minor || verProp.patch != patch || verProp.commit != commit)) {
      return;
    }
     
    Votes votes = verProp.votes;
    for (uint i = 0; i < votes.pass.length; i++) {
      if (votes.pass[i] == msg.sender) {
        return;
      }
    }
    for (i = 0; i < votes.fail.length; i++) {
      if (votes.fail[i] == msg.sender) {
        return;
      }
    }
     
    if (release) {
      votes.pass.push(msg.sender);
      if (votes.pass.length <= voters.length / 2) {
        return;
      }
    } else {
      votes.fail.push(msg.sender);
      if (votes.fail.length <= voters.length / 2) {
        return;
      }
    }
     
    if (release) {
      verProp.time = uint64(now);
      releases.push(verProp);
      delete verProp;
    } else {
      delete verProp;
    }
  }
}