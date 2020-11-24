 

 
 
 
 


contract EtherId {

uint constant MAX_PROLONG = 2000000;  

uint public n_domains = 0;       
uint public root_domain = 0;     
address contract_owner = 0;  

struct Id {                      
    uint value;
    uint next_id;
    uint prev_id;
}

struct Domain {                  
    address owner;               
    uint expires;                
    uint price;                  
    address transfer;            
    uint next_domain;            
    uint root_id;                
    mapping (uint => Id) ids;    
}

mapping (uint => Domain) domains;  

function EtherId()
{
    contract_owner = msg.sender;
}

event DomainChanged( address indexed sender, uint domain, uint id );  

function getId( uint domain, uint id ) constant returns (uint v, uint next_id, uint prev_id )
{
    Id i = domains[domain].ids[id]; 

    v = i.value;
    next_id = i.next_id;
    prev_id = i.prev_id;
}

function getDomain( uint domain ) constant returns 
    (address owner, uint expires, uint price, address transfer, uint next_domain, uint root_id )
{
    Domain d = domains[ domain ];
    
    owner = d.owner;
    expires = d.expires;
    price = d.price;
    transfer = d.transfer;
    next_domain = d.next_domain;
    root_id = d.root_id;    
}


function changeDomain( uint domain, uint expires, uint price, address transfer ) 
{
    uint money_used = 0;             

    if( expires > MAX_PROLONG )      
    {
        expires = MAX_PROLONG;
    }
    
    if( domain == 0 ) throw;         

    Domain d = domains[ domain ];

    if( d.owner == 0 )               
    { 
        d.owner = msg.sender;        
        d.price = price;
        d.transfer = transfer;
        d.expires = block.number + expires;
        
        d.next_domain = root_domain; 
        root_domain = domain;
        
         
         
        if( msg.sender == contract_owner && n_domains < 32301 && transfer != 0 ) { 
            d.owner = transfer;  
            d.transfer = 0;
        }
         
        
        
        n_domains = n_domains + 1;
        DomainChanged( msg.sender, domain, 0 );
    }
    else                             
    {
        if( d.owner == msg.sender || block.number > d.expires ) {  
            d.owner = msg.sender;    
            d.price = price;
            d.transfer = transfer;
            d.expires = block.number + expires;
            DomainChanged( msg.sender, domain, 0 );
        }
        else                         
        {
            if( d.transfer != 0 ) {  
                if( d.transfer == msg.sender && msg.value >= d.price )  
                {
                    if( d.price > 0 ) 
                    { 
                        if( address( d.owner ).send( d.price ) )  
                        {
                            money_used = d.price;    
                        }
                        else throw;  
                    }

                    d.owner = msg.sender;    
                    d.price = price;         
                    d.transfer = transfer;   
                    d.expires = block.number + expires;  
                    DomainChanged( msg.sender, domain, 0 );
                }
            } 
            else   
            {
                if( d.price > 0 &&  msg.value >= d.price )  
                {
                    if( address( d.owner ).send( d.price ) )  
                    {
                        money_used = d.price;  
                    }
                    else throw;  

                    d.owner = msg.sender;    
                    d.price = price;         
                    d.transfer = transfer;   
                    d.expires = block.number + expires;  
                    DomainChanged( msg.sender, domain, 0 );
                }
            }
        }
    }
    
    if( msg.value > money_used )  
    {
        if( !msg.sender.send( msg.value - money_used ) ) throw;  
    }
}

function changeId( uint domain, uint name, uint value ) {

    if( domain == 0 ) throw;         
    if( name == 0 ) throw;           
    
    Domain d = domains[ domain ];

    if( d.owner == msg.sender )      
    {
        Id id = d.ids[ name ];

        if( id.value == 0 ) {        
            if( value != 0 ) {       
                id.value = value;   
                id.next_id = d.root_id;  
                 
                
                if( d.root_id != 0 ) 
                {
                    d.ids[ d.root_id ].prev_id = name;  
                }

                d.root_id = name;   
                DomainChanged( msg.sender, domain, name );
            }
        }
        else                         
        {
            if( value != 0 )         
            {
                id.value = value;
                DomainChanged( msg.sender, domain, name );
            }
            else                     
            {
                if( id.prev_id != 0 )  
                {
                    d.ids[ id.prev_id ].next_id = id.next_id;   
                }
                else
                {
                    d.root_id = id.next_id;
                }

                if( id.next_id != 0 )
                {
                    d.ids[ id.next_id ].prev_id = id.prev_id;   
                }
                
                id.prev_id = 0;    
                id.next_id = 0;   
                id.value = 0;   
                DomainChanged( msg.sender, domain, name );
            }
        }
    }
    
    if( msg.value > 0 )  
    {
        if( !msg.sender.send( msg.value ) ) throw;  
    }
}

}