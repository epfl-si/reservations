/*
Usage:
  export EPFL_API_RESERVATION_USERNAME='reservations'
  export EPFL_API_RESERVATION_PASSWORD='VerySercurePassword'
  node index.js
*/
const username = process.env.EPFL_API_RESERVATION_USERNAME
const password = process.env.EPFL_API_RESERVATION_PASSWORD
const SAR = 'S36745' // Super Admin Reservation 

const options = {
  method: 'GET',
  headers: { authorization: `Basic ${ Buffer.from( username + ':' + password ).toString( 'base64' ) }` }
};

const getGroupOwnedBy = async (owner) => {
  const url = `https://api.epfl.ch/v1/groups?owner=${owner}`
  try {
    const response = await fetch(url, options)
    const data = await response.json()
    return data
  } catch (error) {
    console.error(error)
  }
}

const getAdminOfGroup = async (group) => {
  const url = `https://api.epfl.ch/v1/groups/${group}/admins`
  try {
    const response = await fetch(url, options)
    const data = await response.json()
    //console.log(data.admins)
    return data.admins
  } catch (error) {
    console.error(error)
  }
}

const checkXisAdminOfGroup = async (userOrGroup, group) => {
  const adminOfaGroup = await getAdminOfGroup(group)
  return adminOfaGroup.some( g => g.id == userOrGroup)
}

const addAdminToGroup = async (userOrGroup, group) => {
  const url = `https://api.epfl.ch/v1/groups/${group}/admins`
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: options.headers,
      body: JSON.stringify({ id: userOrGroup })
    })

    const data = await response.json()
    console.log(data)
    console.log(`${userOrGroup} added to ${group} → ${response.status}`)
  } catch (error) {
    console.error(error)
  }
}

const myGroups = await getGroupOwnedBy('M07016')
const adminGroups = myGroups.groups.filter( (e) => e.name.startsWith('calendar_admins_') )
adminGroups.forEach( async g => {
  const check = await checkXisAdminOfGroup(SAR, g.id)
  if ( check ) {
    console.debug(`Oh yeah, SAR is already an admin of ${g.name} (#${g.id})`)
  } else {
    console.debug(`Oh snap! SAR is NOT an admin of ${g.name} (#${g.id})`)
    await addAdminToGroup(SAR, g.id)
  }
})
