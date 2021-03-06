import "../../../dao-stl/src/errors/Errors.sol";
import "./Permission.sol";
import "./Doug.sol";

/// @title DefaultPermission
/// @author Andreas Olofsson (androlo1980@gmail.com)
/// @dev Default permission contract. Implements the 'Permission' interface.
/// Root is the only account allowed to add and and remove owners.
/// Root and owners all pass the 'isPermission' check.
contract DefaultPermission is Destructible, Permission, Errors {

    struct OElement {
        uint _keyIndex;
        uint _timestamp;
    }

    struct OMap
    {
        mapping(address => OElement) _data;
        address[] _keys;
    }

    address _root;
    uint _timeRootAdded;

    OMap _owners;

    // Constructor
    function DefaultPermission(address root) {
        _root = root;
        _timeRootAdded = block.timestamp;
    }

    /// @notice DefaultPermission.setRoot(newRoot) to set the root account address.
    /// @dev Set the root account address. Can only be done when caller is 'root'.
    /// @param newRoot (address) the address
    /// @return error (uint16) error code
    function setRoot(address newRoot) constant returns (uint16 error) {
        if (msg.sender != _root)
            return ACCESS_DENIED;
        _root = newRoot;
        // Remove new root from owner list if he was in there.
        if (_owners._data[newRoot]._timestamp != 0)
            delete _owners._data[newRoot];
        _timeRootAdded = block.timestamp;
    }


    /// @notice DefaultPermission.root() to get the root address.
    /// @dev Get the root address.
    /// @return root (address) the address of root.
    function root() constant returns (address root) {
        return _root;
    }

    /// @notice DefaultPermission.rootData() to get the address of root, and the time they were added.
    /// @dev Get the address of root, and the time they were created.
    /// @return root (address) the address|
    /// @return timeRootAdded (uint) the time when root was added.
    function rootData() constant returns (address root, uint timeRootAdded) {
        root = _root;
        timeRootAdded = _timeRootAdded;
    }

    /// @notice DefaultPermission.addOwner(addr) to add a new owner.
    /// @dev Add a new owner. Can only be done by 'root'.
    /// @param addr (address) the address of the new owner
    /// @return error (uint16) error code
    function addOwner(address addr) returns (uint16 error) {
        // Basic check for null value.
        if(addr == 0)
            return NULL_PARAM_NOT_ALLOWED;
        if(addr == _root)
            return INVALID_PARAM_VALUE;
        // If sender isn't root they can't add new owners.
        if(msg.sender != _root)
            return ACCESS_DENIED;

        var exists = _owners._data[addr]._timestamp != 0;
        if (exists)
            return RESOURCE_ALREADY_EXISTS;
        else {
            var keyIndex = _owners._keys.length++;
            _owners._data[addr] = OElement(keyIndex, block.timestamp);
            _owners._keys[keyIndex] = addr;
        }
    }

    /// @notice DefaultPermission.removeOwner(addr) to remove an owner.
    /// @dev Remove an owner. Can only be done by 'root' and the owner himself.
    /// @param addr (address) the address of the owner
    /// @return error (uint16) error code
    function removeOwner(address addr) returns (uint16 error) {
        // Basic check for null value.
        if (addr == 0)
            return NULL_PARAM_NOT_ALLOWED;
        // If sender isn't an owner of 'perm' (or root) they can't add new owners.
        if (msg.sender != _root && msg.sender != addr)
            return ACCESS_DENIED;

        var elem = _owners._data[addr];

        var exists = elem._timestamp != 0;
        if (!exists)
            return RESOURCE_NOT_FOUND;

        var keyIndex = elem._keyIndex;
        delete _owners._data[addr];
        var len = _owners._keys.length;
        if (keyIndex != len - 1) {
            var swap = _owners._keys[len - 1];
            _owners._keys[keyIndex] = swap;
            _owners._data[swap]._keyIndex = keyIndex;
        }
        _owners._keys.length--;
    }

    /// @notice DefaultPermission.ownerTimestamp(addr) to get the time when the owner was added.
    /// @dev Get the time when the owner was added.
    /// @param addr (address) the owner address
    /// @return timestamp (uint) the time when the owner was added|
    /// @return error (uint16) error code
    function ownerTimestamp(address addr) constant returns (uint timestamp, uint16 error) {
        timestamp = _owners._data[addr]._timestamp;
        if (timestamp == 0)
            error = RESOURCE_NOT_FOUND;
    }

    /// @notice DefaultPermission.ownerFromIndex(index) to get the owner with position 'index' in the backing array.
    /// @dev Get the owner with position 'index' in the backing array.
    /// @param index (uint) the index.
    /// @return owner (address) the owner address|
    /// @return timestamp (uint) the time when the owner was added|
    /// @return error (uint16) error code
    function ownerFromIndex(uint index) constant returns (address owner, uint timestamp, uint16 error) {
        if (index >= _owners._keys.length){
            error = ARRAY_INDEX_OUT_OF_BOUNDS;
            return;
        }
        owner = _owners._keys[index];
        timestamp = _owners._data[owner]._timestamp;
        return;
    }

    /// @notice DefaultPermission.numOwners() to get the total number of owners.
    /// @dev Get the total number of owners.
    /// @return numOwners (uint) the number of owners
    function numOwners() constant returns (uint numOwners) {
        return _owners._keys.length;
    }

    /// @notice DefaultPermission.hasPermission(addr) to check if an address has this permission.
    /// @dev Check if an address has this permission.
    /// @param addr (address) the address
    /// @return hasPerm (bool) true if the address is either root or an owner, false otherwise.
    function hasPermission(address addr) constant returns (bool hasPerm) {
        return addr == _root || _owners._data[addr]._timestamp != 0;
    }

    /// @notice DefaultPermission.destroy() to destroy the contract.
    /// @dev Calls 'selfdestruct' if caller is root.
    /// @param fundReceiver (address) the account that receives the funds.
    function destroy(address fundReceiver) {
        if (msg.sender == _root)
            selfdestruct(fundReceiver);
    }

}