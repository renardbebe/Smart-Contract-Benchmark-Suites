 

 
pragma solidity ^0.4.11;

 


 
 
contract ILiquidPledgingPlugin {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function beforeTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount ) returns (uint maxAllowed);

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function afterTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
    );
}

 
pragma solidity ^0.4.15;


 
 
 
 
 
 
 
 
 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

     
    function Owned() public {
        owner = msg.sender;
    }

     
     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
     
     
     
     
     
     
    function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
     
    function acceptOwnership() public {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
    function changeOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
     
    function removeOwnership(address _dac) public onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        OwnershipRemoved();     
    }
} 

 
pragma solidity ^0.4.15;


 
contract ERC20 {
  
     
    function totalSupply() public constant returns (uint256 supply);

     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
pragma solidity ^0.4.15;
 





 
 
 
 
 
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist;  

     
     
     
     
     
     
     
     
     
     
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

     
     
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

     
     
     
     
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

     
     
     
     
    function isTokenEscapable(address _token) constant public returns (bool) {
        return !escapeBlacklist[_token];
    }

     
     
     
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

         
        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }
         
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance));
        EscapeHatchCalled(_token, balance);
    }

     
     
     
     
     
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}

 
pragma solidity ^0.4.11;
 




 
 
 
interface LPVault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount);
    function () payable;
}

 
 
 
contract LiquidPledgingBase is Escapable {

     
    uint constant MAX_DELEGATES = 20;
    uint constant MAX_SUBPROJECT_LEVEL = 20;
    uint constant MAX_INTERPROJECT_LEVEL = 20;

    enum PledgeAdminType { Giver, Delegate, Project }
    enum PledgeState { Pledged, Paying, Paid }

     
     
     
    struct PledgeAdmin { 
        PledgeAdminType adminType;  
        address addr;  
        string name;
        string url;   
        uint64 commitTime;   
        uint64 parentProject;   
        bool canceled;       

         
         
        ILiquidPledgingPlugin plugin; 
    }

    struct Pledge {
        uint amount;
        uint64 owner;  
        uint64[] delegationChain;  
        uint64 intendedProject;  
        uint64 commitTime;   
        uint64 oldPledge;  
        PledgeState pledgeState;  
    }

    Pledge[] pledges;
    PledgeAdmin[] admins;  
    LPVault public vault;

     
     
    mapping (bytes32 => uint64) hPledge2idx;
    mapping (bytes32 => bool) pluginWhitelist;
    
    bool public usePluginWhitelist = true;

 
 
 


     
     
    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }


 
 
 

     
     
    function LiquidPledgingBase(
        address _vault,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    ) Escapable(_escapeHatchCaller, _escapeHatchDestination) public {
        admins.length = 1;  
        pledges.length = 1;  
        vault = LPVault(_vault);  
    }


 
 
 

     
     
     
     
     
     
     
     
    function addGiver(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idGiver) {

        require(isValidPlugin(plugin));  

        idGiver = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Giver,
            msg.sender,
            name,
            url,
            commitTime,
            0,
            false,
            plugin));

        GiverAdded(idGiver);
    }

    event GiverAdded(uint64 indexed idGiver);

     
     
     
     
     
     
     
     
     
    function updateGiver(
        uint64 idGiver,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime)
    {
        PledgeAdmin storage giver = findAdmin(idGiver);
        require(giver.adminType == PledgeAdminType.Giver);  
        require(giver.addr == msg.sender);  
        giver.addr = newAddr;
        giver.name = newName;
        giver.url = newUrl;
        giver.commitTime = newCommitTime;
        GiverUpdated(idGiver);
    }

    event GiverUpdated(uint64 indexed idGiver);

     
     
     
     
     
     
     
     
     
     
    function addDelegate(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idDelegate) { 

        require(isValidPlugin(plugin));  

        idDelegate = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Delegate,
            msg.sender,
            name,
            url,
            commitTime,
            0,
            false,
            plugin));

        DelegateAdded(idDelegate);
    }

    event DelegateAdded(uint64 indexed idDelegate);

     
     
     
     
     
     
     
     
     
     
     
    function updateDelegate(
        uint64 idDelegate,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime) {
        PledgeAdmin storage delegate = findAdmin(idDelegate);
        require(delegate.adminType == PledgeAdminType.Delegate);
        require(delegate.addr == msg.sender); 
        delegate.addr = newAddr;
        delegate.name = newName;
        delegate.url = newUrl;
        delegate.commitTime = newCommitTime;
        DelegateUpdated(idDelegate);
    }

    event DelegateUpdated(uint64 indexed idDelegate);

     
     
     
     
     
     
     
     
     
     
     
     
    function addProject(
        string name,
        string url,
        address projectAdmin,
        uint64 parentProject,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idProject) {
        require(isValidPlugin(plugin));

        if (parentProject != 0) {
            PledgeAdmin storage pa = findAdmin(parentProject);
            require(pa.adminType == PledgeAdminType.Project);
            require(getProjectLevel(pa) < MAX_SUBPROJECT_LEVEL);
        }

        idProject = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Project,
            projectAdmin,
            name,
            url,
            commitTime,
            parentProject,
            false,
            plugin));


        ProjectAdded(idProject);
    }

    event ProjectAdded(uint64 indexed idProject);


     
     
     
     
     
     
     
     
     
     
    function updateProject(
        uint64 idProject,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime)
    {
        PledgeAdmin storage project = findAdmin(idProject);
        require(project.adminType == PledgeAdminType.Project);
        require(project.addr == msg.sender);
        project.addr = newAddr;
        project.name = newName;
        project.url = newUrl;
        project.commitTime = newCommitTime;
        ProjectUpdated(idProject);
    }

    event ProjectUpdated(uint64 indexed idAdmin);


 
 
 

     
     
    function numberOfPledges() constant returns (uint) {
        return pledges.length - 1;
    }

     
     
     
     
     
    function getPledge(uint64 idPledge) constant returns(
        uint amount,
        uint64 owner,
        uint64 nDelegates,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PledgeState pledgeState
    ) {
        Pledge storage p = findPledge(idPledge);
        amount = p.amount;
        owner = p.owner;
        nDelegates = uint64(p.delegationChain.length);
        intendedProject = p.intendedProject;
        commitTime = p.commitTime;
        oldPledge = p.oldPledge;
        pledgeState = p.pledgeState;
    }

     
     
     
    function getPledgeDelegate(uint64 idPledge, uint idxDelegate) constant returns(
        uint64 idDelegate,
        address addr,
        string name
    ) {
        Pledge storage p = findPledge(idPledge);
        idDelegate = p.delegationChain[idxDelegate - 1];
        PledgeAdmin storage delegate = findAdmin(idDelegate);
        addr = delegate.addr;
        name = delegate.name;
    }

     
     
    function numberOfPledgeAdmins() constant returns(uint) {
        return admins.length - 1;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function getPledgeAdmin(uint64 idAdmin) constant returns (
        PledgeAdminType adminType,
        address addr,
        string name,
        string url,
        uint64 commitTime,
        uint64 parentProject,
        bool canceled,
        address plugin)
    {
        PledgeAdmin storage m = findAdmin(idAdmin);
        adminType = m.adminType;
        addr = m.addr;
        name = m.name;
        url = m.url;
        commitTime = m.commitTime;
        parentProject = m.parentProject;
        canceled = m.canceled;
        plugin = address(m.plugin);
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function findOrCreatePledge(
        uint64 owner,
        uint64[] delegationChain,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PledgeState state
        ) internal returns (uint64)
    {
        bytes32 hPledge = sha3(
            owner, delegationChain, intendedProject, commitTime, oldPledge, state);
        uint64 idx = hPledge2idx[hPledge];
        if (idx > 0) return idx;
        idx = uint64(pledges.length);
        hPledge2idx[hPledge] = idx;
        pledges.push(Pledge(
            0, owner, delegationChain, intendedProject, commitTime, oldPledge, state));
        return idx;
    }

     
     
     
    function findAdmin(uint64 idAdmin) internal returns (PledgeAdmin storage) {
        require(idAdmin < admins.length);
        return admins[idAdmin];
    }

     
     
     
    function findPledge(uint64 idPledge) internal returns (Pledge storage) {
        require(idPledge < pledges.length);
        return pledges[idPledge];
    }

     
    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;

     
     
     
     
     
     
     
     
    function getDelegateIdx(Pledge p, uint64 idDelegate) internal returns(uint64) {
        for (uint i=0; i < p.delegationChain.length; i++) {
            if (p.delegationChain[i] == idDelegate) return uint64(i);
        }
        return NOTFOUND;
    }

     
     
     
     
    function getPledgeLevel(Pledge p) internal returns(uint) {
        if (p.oldPledge == 0) return 0;
        Pledge storage oldN = findPledge(p.oldPledge);
        return getPledgeLevel(oldN) + 1;  
    }

     
     
     
     
    function maxCommitTime(Pledge p) internal returns(uint commitTime) {
        PledgeAdmin storage m = findAdmin(p.owner);
        commitTime = m.commitTime;  

        for (uint i=0; i<p.delegationChain.length; i++) {
            m = findAdmin(p.delegationChain[i]);

             
            if (m.commitTime > commitTime) commitTime = m.commitTime;
        }
    }

     
     
     
     
    function getProjectLevel(PledgeAdmin m) internal returns(uint) {
        assert(m.adminType == PledgeAdminType.Project);
        if (m.parentProject == 0) return(1);
        PledgeAdmin storage parentNM = findAdmin(m.parentProject);
        return getProjectLevel(parentNM) + 1;
    }

     
     
     
    function isProjectCanceled(uint64 projectId) constant returns (bool) {
        PledgeAdmin storage m = findAdmin(projectId);
        if (m.adminType == PledgeAdminType.Giver) return false;
        assert(m.adminType == PledgeAdminType.Project);
        if (m.canceled) return true;
        if (m.parentProject == 0) return false;
        return isProjectCanceled(m.parentProject);
    }

     
     
     
    function getOldestPledgeNotCanceled(uint64 idPledge
        ) internal constant returns(uint64) {
        if (idPledge == 0) return 0;
        Pledge storage p = findPledge(idPledge);
        PledgeAdmin storage admin = findAdmin(p.owner);
        if (admin.adminType == PledgeAdminType.Giver) return idPledge;

        assert(admin.adminType == PledgeAdminType.Project);

        if (!isProjectCanceled(p.owner)) return idPledge;

        return getOldestPledgeNotCanceled(p.oldPledge);
    }

     
     
     
    function checkAdminOwner(PledgeAdmin m) internal constant {
        require((msg.sender == m.addr) || (msg.sender == address(m.plugin)));
    }
 
 
 

    function addValidPlugin(bytes32 contractHash) external onlyOwner {
        pluginWhitelist[contractHash] = true;
    }

    function removeValidPlugin(bytes32 contractHash) external onlyOwner {
        pluginWhitelist[contractHash] = false;
    }

    function useWhitelist(bool useWhitelist) external onlyOwner {
        usePluginWhitelist = useWhitelist;
    }

    function isValidPlugin(address addr) public returns(bool) {
        if (!usePluginWhitelist || addr == 0x0) return true;

        bytes32 contractHash = getCodeHash(addr);

        return pluginWhitelist[contractHash];
    }

    function getCodeHash(address addr) public returns(bytes32) {
        bytes memory o_code;
        assembly {
             
            let size := extcodesize(addr)
             
             
            o_code := mload(0x40)
             
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
             
            mstore(o_code, size)
             
            extcodecopy(addr, add(o_code, 0x20), 0, size)
        }
        return keccak256(o_code);
    }
}

 
pragma solidity ^0.4.11;

 

 


 
 
 
 
contract LiquidPledging is LiquidPledgingBase {


 
 
 

     
     
     
     
     
    function LiquidPledging(
        address _vault,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    ) LiquidPledgingBase(_vault, _escapeHatchCaller, _escapeHatchDestination) {

    }

     
     
     
     
     
     
     
    function donate(uint64 idGiver, uint64 idReceiver) payable {
        if (idGiver == 0) {
             
            idGiver = addGiver("", "", 259200, ILiquidPledgingPlugin(0x0));
        }

        PledgeAdmin storage sender = findAdmin(idGiver);

        checkAdminOwner(sender);

        require(sender.adminType == PledgeAdminType.Giver);

        uint amount = msg.value;

        require(amount > 0);

        vault.transfer(amount);  
        uint64 idPledge = findOrCreatePledge(
            idGiver,
            new uint64[](0),  
            0,
            0,
            0,
            PledgeState.Pledged
        );


        Pledge storage nTo = findPledge(idPledge);
        nTo.amount += amount;

        Transfer(0, idPledge, amount);

        transfer(idGiver, idPledge, amount, idReceiver);
    }


     
     
     
     
     
     
     
     
     
     
    function transfer(
        uint64 idSender,
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    )
    {

        idPledge = normalizePledge(idPledge);

        Pledge storage p = findPledge(idPledge);
        PledgeAdmin storage receiver = findAdmin(idReceiver);
        PledgeAdmin storage sender = findAdmin(idSender);

        checkAdminOwner(sender);
        require(p.pledgeState == PledgeState.Pledged);

         
        if (p.owner == idSender) {
            if (receiver.adminType == PledgeAdminType.Giver) {
                transferOwnershipToGiver(idPledge, amount, idReceiver);
            } else if (receiver.adminType == PledgeAdminType.Project) {
                transferOwnershipToProject(idPledge, amount, idReceiver);
            } else if (receiver.adminType == PledgeAdminType.Delegate) {
                idPledge = undelegate(
                    idPledge,
                    amount,
                    p.delegationChain.length
                );
                appendDelegate(idPledge, amount, idReceiver);
            } else {
                assert(false);
            }
            return;
        }

         
        uint senderDIdx = getDelegateIdx(p, idSender);
        if (senderDIdx != NOTFOUND) {

             
            if (receiver.adminType == PledgeAdminType.Giver) {
                 
                 
                assert(p.owner == idReceiver);
                undelegate(idPledge, amount, p.delegationChain.length);
                return;
            }

             
            if (receiver.adminType == PledgeAdminType.Delegate) {
                uint receiverDIdx = getDelegateIdx(p, idReceiver);

                 
                if (receiverDIdx == NOTFOUND) {
                    idPledge = undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length - senderDIdx - 1
                    );
                    appendDelegate(idPledge, amount, idReceiver);

                 
                 
                 
                 
                } else if (receiverDIdx > senderDIdx) {
                    idPledge = undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length - senderDIdx - 1
                    );
                    appendDelegate(idPledge, amount, idReceiver);

                 
                 
                 
                 
                 
                 
                } else if (receiverDIdx <= senderDIdx) {
                    undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length - receiverDIdx - 1
                    );
                }
                return;
            }

             
             
            if (receiver.adminType == PledgeAdminType.Project) {
                idPledge = undelegate(
                    idPledge,
                    amount,
                    p.delegationChain.length - senderDIdx - 1
                );
                proposeAssignProject(idPledge, amount, idReceiver);
                return;
            }
        }
        assert(false);   
    }

     
     
     
     
    function withdraw(uint64 idPledge, uint amount) {

        idPledge = normalizePledge(idPledge);

        Pledge storage p = findPledge(idPledge);

        require(p.pledgeState == PledgeState.Pledged);

        PledgeAdmin storage owner = findAdmin(p.owner);

        checkAdminOwner(owner);

        uint64 idNewPledge = findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Paying
        );

        doTransfer(idPledge, idNewPledge, amount);

        vault.authorizePayment(bytes32(idNewPledge), owner.addr, amount);
    }

     
     
     
    function confirmPayment(uint64 idPledge, uint amount) onlyVault {
        Pledge storage p = findPledge(idPledge);

        require(p.pledgeState == PledgeState.Paying);

        uint64 idNewPledge = findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Paid
        );

        doTransfer(idPledge, idNewPledge, amount);
    }

     
     
     
    function cancelPayment(uint64 idPledge, uint amount) onlyVault {
        Pledge storage p = findPledge(idPledge);

        require(p.pledgeState == PledgeState.Paying);  

         
        uint64 oldPledge = findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Pledged
        );

        oldPledge = normalizePledge(oldPledge);

        doTransfer(idPledge, oldPledge, amount);
    }

     
     
    function cancelProject(uint64 idProject) {
        PledgeAdmin storage project = findAdmin(idProject);
        checkAdminOwner(project);
        project.canceled = true;

        CancelProject(idProject);
    }

     
     
     
    function cancelPledge(uint64 idPledge, uint amount) {
        idPledge = normalizePledge(idPledge);

        Pledge storage p = findPledge(idPledge);
        require(p.oldPledge != 0);

        PledgeAdmin storage m = findAdmin(p.owner);
        checkAdminOwner(m);

        uint64 oldPledge = getOldestPledgeNotCanceled(p.oldPledge);
        doTransfer(idPledge, oldPledge, amount);
    }


 
 
 

     
     
    
    
     
    uint constant D64 = 0x10000000000000000;

     
     
     
     
     
     
     
     
     
     
    function mTransfer(
        uint64 idSender,
        uint[] pledgesAmounts,
        uint64 idReceiver
    ) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            transfer(idSender, idPledge, amount, idReceiver);
        }
    }

     
     
     
     
    function mWithdraw(uint[] pledgesAmounts) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            withdraw(idPledge, amount);
        }
    }

     
     
     
     
    function mConfirmPayment(uint[] pledgesAmounts) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            confirmPayment(idPledge, amount);
        }
    }

     
     
     
     
    function mCancelPayment(uint[] pledgesAmounts) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            cancelPayment(idPledge, amount);
        }
    }

     
     
     
    function mNormalizePledge(uint64[] pledges) {
        for (uint i = 0; i < pledges.length; i++ ) {
            normalizePledge( pledges[i] );
        }
    }

 
 
 

     
     
     
     
     
     
    function transferOwnershipToProject(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        Pledge storage p = findPledge(idPledge);

         
         
        require(getPledgeLevel(p) < MAX_INTERPROJECT_LEVEL);
        require(!isProjectCanceled(idReceiver));

        uint64 oldPledge = findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Pledged
        );
        uint64 toPledge = findOrCreatePledge(
            idReceiver,                      
            new uint64[](0),                 
            0,
            0,
            oldPledge,
            PledgeState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }   


     
     
     
     
     
     
    function transferOwnershipToGiver(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        uint64 toPledge = findOrCreatePledge(
            idReceiver,
            new uint64[](0),
            0,
            0,
            0,
            PledgeState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }

     
     
     
     
     
    function appendDelegate(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        Pledge storage p = findPledge(idPledge);

        require(p.delegationChain.length < MAX_DELEGATES);
        uint64[] memory newDelegationChain = new uint64[](
            p.delegationChain.length + 1
        );
        for (uint i = 0; i<p.delegationChain.length; i++) {
            newDelegationChain[i] = p.delegationChain[i];
        }

         
        newDelegationChain[p.delegationChain.length] = idReceiver;

        uint64 toPledge = findOrCreatePledge(
            p.owner,
            newDelegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }

     
     
     
     
     
    function undelegate(
        uint64 idPledge,
        uint amount,
        uint q
    ) internal returns (uint64){
        Pledge storage p = findPledge(idPledge);
        uint64[] memory newDelegationChain = new uint64[](
            p.delegationChain.length - q
        );
        for (uint i=0; i<p.delegationChain.length - q; i++) {
            newDelegationChain[i] = p.delegationChain[i];
        }
        uint64 toPledge = findOrCreatePledge(
            p.owner,
            newDelegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);

        return toPledge;
    }

     
     
     
     
     
     
     
    function proposeAssignProject(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        Pledge storage p = findPledge(idPledge);

        require(getPledgeLevel(p) < MAX_INTERPROJECT_LEVEL);
        require(!isProjectCanceled(idReceiver));

        uint64 toPledge = findOrCreatePledge(
            p.owner,
            p.delegationChain,
            idReceiver,
            uint64(getTime() + maxCommitTime(p)),
            p.oldPledge,
            PledgeState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }

     
     
     
     
     
    function doTransfer(uint64 from, uint64 to, uint _amount) internal {
        uint amount = callPlugins(true, from, to, _amount);
        if (from == to) { 
            return;
        }
        if (amount == 0) {
            return;
        }
        Pledge storage nFrom = findPledge(from);
        Pledge storage nTo = findPledge(to);
        require(nFrom.amount >= amount);
        nFrom.amount -= amount;
        nTo.amount += amount;

        Transfer(from, to, amount);
        callPlugins(false, from, to, amount);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function normalizePledge(uint64 idPledge) returns(uint64) {

        Pledge storage p = findPledge(idPledge);

         
         
        if (p.pledgeState != PledgeState.Pledged) {
            return idPledge;
        }

         
        if ((p.intendedProject > 0) && ( getTime() > p.commitTime)) {
            uint64 oldPledge = findOrCreatePledge(
                p.owner,
                p.delegationChain,
                0,
                0,
                p.oldPledge,
                PledgeState.Pledged
            );
            uint64 toPledge = findOrCreatePledge(
                p.intendedProject,
                new uint64[](0),
                0,
                0,
                oldPledge,
                PledgeState.Pledged
            );
            doTransfer(idPledge, toPledge, p.amount);
            idPledge = toPledge;
            p = findPledge(idPledge);
        }

        toPledge = getOldestPledgeNotCanceled(idPledge);
        if (toPledge != idPledge) {
            doTransfer(idPledge, toPledge, p.amount);
        }

        return toPledge;
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function callPlugin(
        bool before,
        uint64 adminId,
        uint64 fromPledge,
        uint64 toPledge,
        uint64 context,
        uint amount
    ) internal returns (uint allowedAmount) {

        uint newAmount;
        allowedAmount = amount;
        PledgeAdmin storage admin = findAdmin(adminId);
         
        if ((address(admin.plugin) != 0) && (allowedAmount > 0)) {
             
             
            if (before) {
                newAmount = admin.plugin.beforeTransfer(
                    adminId,
                    fromPledge,
                    toPledge,
                    context,
                    amount
                );
                require(newAmount <= allowedAmount);
                allowedAmount = newAmount;
            } else {
                admin.plugin.afterTransfer(
                    adminId,
                    fromPledge,
                    toPledge,
                    context,
                    amount
                );
            }
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function callPluginsPledge(
        bool before,
        uint64 idPledge,
        uint64 fromPledge,
        uint64 toPledge,
        uint amount
    ) internal returns (uint allowedAmount) {
         
         
        uint64 offset = idPledge == fromPledge ? 0 : 256;
        allowedAmount = amount;
        Pledge storage p = findPledge(idPledge);

         
        allowedAmount = callPlugin(
            before,
            p.owner,
            fromPledge,
            toPledge,
            offset,
            allowedAmount
        );

         
        for (uint64 i=0; i<p.delegationChain.length; i++) {
            allowedAmount = callPlugin(
                before,
                p.delegationChain[i],
                fromPledge,
                toPledge,
                offset + i+1,
                allowedAmount
            );
        }

         
         
         
        if (p.intendedProject > 0) {
            allowedAmount = callPlugin(
                before,
                p.intendedProject,
                fromPledge,
                toPledge,
                offset + 255,
                allowedAmount
            );
        }
    }


     
     
     
     
     
     
     
     
    function callPlugins(
        bool before,
        uint64 fromPledge,
        uint64 toPledge,
        uint amount
    ) internal returns (uint allowedAmount) {
        allowedAmount = amount;

         
        allowedAmount = callPluginsPledge(
            before,
            fromPledge,
            fromPledge,
            toPledge,
            allowedAmount
        );

         
        allowedAmount = callPluginsPledge(
            before,
            toPledge,
            fromPledge,
            toPledge,
            allowedAmount
        );
    }

 
 
 

     
    function getTime() internal returns (uint) {
        return now;
    }

     
    event Transfer(uint64 indexed from, uint64 indexed to, uint amount);
    event CancelProject(uint64 indexed idProject);

}

 
pragma solidity ^0.4.18;

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

 
pragma solidity ^0.4.18;

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

 
pragma solidity ^0.4.18;

 

 
 
 
 
 
 
 




contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.2';  


     
     
     
    struct  Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

           return true;
    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

         
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

         
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

         
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

 
pragma solidity ^0.4.13;





 
 
 
 
 
 
 
 
 
contract LPPCampaign is Escapable, TokenController {
    uint constant FROM_OWNER = 0;
    uint constant FROM_PROPOSEDPROJECT = 255;
    uint constant TO_OWNER = 256;
    uint constant TO_PROPOSEDPROJECT = 511;

    LiquidPledging public liquidPledging;
    MiniMeToken public token;
    bool public initPending;
    uint64 public idProject;
    address public reviewer;
    address public newReviewer;

    event GenerateTokens(address indexed liquidPledging, address addr, uint amount);

    function LPPCampaign(
        LiquidPledging _liquidPledging,
        string tokenName,
        string tokenSymbol,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    ) Escapable(_escapeHatchCaller, _escapeHatchDestination) public
    {
      require(msg.sender != tx.origin);
      liquidPledging = _liquidPledging;
      MiniMeTokenFactory tokenFactory = new MiniMeTokenFactory();
      token = new MiniMeToken(tokenFactory, 0x0, 0, tokenName, 18, tokenSymbol, false);
      initPending = true;
    }

    function init(
        string name,
        string url,
        uint64 parentProject,
        address _reviewer
    ) {
        require(initPending);
        idProject = liquidPledging.addProject(name, url, address(this), parentProject, 0, ILiquidPledgingPlugin(this));
        reviewer = _reviewer;
        initPending = false;
    }

    modifier initialized() {
      require(!initPending);
      _;
    }

    modifier onlyReviewer() {
        require(msg.sender == reviewer);
        _;
    }

    modifier onlyOwnerOrReviewer() {
        require( msg.sender == owner || msg.sender == reviewer );
        _;
    }

    function changeReviewer(address _newReviewer) public initialized onlyReviewer {
        newReviewer = _newReviewer;
    }

    function acceptNewReviewer() public initialized {
        require(newReviewer == msg.sender);
        reviewer = newReviewer;
        newReviewer = 0;
    }

    function beforeTransfer(
        uint64 pledgeAdmin,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
    ) external initialized returns (uint maxAllowed) {
        require(msg.sender == address(liquidPledging));
        var (, , , fromProposedProject , , , ) = liquidPledging.getPledge(pledgeFrom);
        var (, , , , , , toPledgeState ) = liquidPledging.getPledge(pledgeTo);

         
        if ( (context == TO_OWNER) && (toPledgeState != LiquidPledgingBase.PledgeState.Pledged) ) return 0;

         
         
        if ( (context == TO_PROPOSEDPROJECT)
            || ( (context == TO_OWNER) && (fromProposedProject != idProject) ))
        {
            if (isCanceled()) return 0;
        }
        return amount;
    }

    function afterTransfer(
        uint64 pledgeAdmin,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
    ) external initialized {
      require(msg.sender == address(liquidPledging));
      var (, , , , , , toPledgeState) = liquidPledging.getPledge(pledgeTo);
      var (, fromOwner, , , , , ) = liquidPledging.getPledge(pledgeFrom);

       
      if ( (context == TO_OWNER) &&
              (toPledgeState == LiquidPledgingBase.PledgeState.Pledged)) {
        var (, fromAddr , , , , , , ) = liquidPledging.getPledgeAdmin(fromOwner);

        token.generateTokens(fromAddr, amount);
        GenerateTokens(liquidPledging, fromAddr, amount);
      }
    }

    function cancelCampaign() public initialized onlyOwnerOrReviewer {
        require( !isCanceled() );

        liquidPledging.cancelProject(idProject);
    }

    function transfer(uint64 idPledge, uint amount, uint64 idReceiver) public initialized onlyOwner {
      require( !isCanceled() );

      liquidPledging.transfer(idProject, idPledge, amount, idReceiver);
    }

    function isCanceled() public constant initialized returns (bool) {
      return liquidPledging.isProjectCanceled(idProject);
    }

     
     
     
     
     
    function sendTransaction(address destination, uint value, bytes data) public initialized onlyOwner {
      require(destination.call.value(value)(data));
    }

 
 
 

   
   
   
  function proxyPayment(address _owner) public payable initialized returns(bool) {
    return false;
  }

   
   
   
   
   
   
  function onTransfer(address _from, address _to, uint _amount) public initialized returns(bool) {
    return false;
  }

   
   
   
   
   
   
  function onApprove(address _owner, address _spender, uint _amount) public initialized returns(bool) {
    return false;
  }
}

 
pragma solidity ^0.4.13;



contract LPPCampaignFactory is Escapable {

    function LPPCampaignFactory(address _escapeHatchCaller, address _escapeHatchDestination)
        Escapable(_escapeHatchCaller, _escapeHatchDestination)
    {
    }

    function deploy(
        LiquidPledging liquidPledging,
        string name,
        string url,
        uint64 parentProject,
        address reviewer,
        string tokenName,
        string tokenSymbol,
        address escapeHatchCaller,
        address escapeHatchDestination
  ) {
        LPPCampaign campaign = new LPPCampaign(liquidPledging, tokenName, tokenSymbol, escapeHatchCaller, escapeHatchDestination);
        campaign.init(name, url, parentProject, reviewer);
        campaign.changeOwnership(msg.sender);
    }
}