const repo='GroupDev-Web/ImiganeOS';
const editions=[
  {name:'Windows 95',slug:'95',era:'1995',desc:'Classic gray chrome, compact controls, and the unmistakable Windows 95 feel.'},
  {name:'Windows XP',slug:'XP',era:'2001',desc:'Bright Luna-era styling and the friendliest desktop Microsoft ever shipped.'},
  {name:'Windows Vista',slug:'Vista',era:'2007',desc:'Glass-inspired chrome and a darker, more polished mid-2000s desktop.'},
  {name:'Windows 7',slug:'7',era:'2009',desc:'Aero-era polish with a familiar taskbar and clean glass-like presentation.'},
  {name:'Windows 10',slug:'10',era:'2015',desc:'Flat modern styling with the practical layout people used for years.'},
  {name:'Windows 11',slug:'11',era:'2021',desc:'A newer rounded desktop experience on top of the same ImagineOS Linux core.'}
];

const grid=document.getElementById('edition-grid');
const status=document.getElementById('build-status');

function artifactName(edition,arch){return `ImagineOS-Windows-${edition.slug}-${arch}`}
function artifactUrl(name){return `https://nightly.link/${repo}/workflows/build.yml/main/${name}.zip`}

function render(artifacts=[]){
  grid.innerHTML='';
  for(const edition of editions){
    const card=document.createElement('article');
    card.className='edition-card';
    const top=document.createElement('div');
    top.innerHTML=`<span class="era">${edition.era} edition</span><h3>${edition.name}</h3><p>${edition.desc}</p>`;
    const row=document.createElement('div');
    row.className='download-row';
    for(const arch of ['x86_64','x86']){
      const name=artifactName(edition,arch);
      const ready=artifacts.some(a=>a.name===name&&!a.expired);
      const link=document.createElement('a');
      link.className='download-link'+(ready?'':' disabled');
      link.textContent=arch==='x86_64'?'64-bit':'32-bit';
      link.href=ready?artifactUrl(name):`https://github.com/${repo}/actions/workflows/build.yml`;
      link.title=ready?`Download latest ${edition.name} ${arch} build`:'Build not currently available';
      row.append(link);
    }
    card.append(top,row);
    grid.append(card);
  }
}

render();
fetch(`https://api.github.com/repos/${repo}/actions/artifacts?per_page=100`,{headers:{Accept:'application/vnd.github+json'}})
  .then(r=>{if(!r.ok)throw new Error('GitHub API unavailable');return r.json()})
  .then(data=>{
    const artifacts=(data.artifacts||[]).sort((a,b)=>new Date(b.created_at)-new Date(a.created_at));
    render(artifacts);
    const expected=editions.flatMap(e=>['x86_64','x86'].map(a=>artifactName(e,a)));
    const ready=expected.filter(name=>artifacts.some(a=>a.name===name&&!a.expired)).length;
    status.textContent=ready?`${ready} of ${expected.length} latest builds available`:'No current artifacts yet';
  })
  .catch(()=>{status.textContent='Build status unavailable';});
